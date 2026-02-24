#!/usr/bin/env luajit
--[[
  Font Bitmap Generator
  Converts TTF fonts to C bitmap arrays for the RGB display font system.
  
  Usage: luajit generate_font.lua <ttf_file> <font_name> <pixel_size>
  Example: luajit generate_font.lua EBGaramond-Regular.ttf garamond 16
  
  Requires: LuaJIT with FFI, FreeType library installed
]]

local ffi = require("ffi")
local bit = require("bit")

ffi.cdef[[
  typedef int FT_Error;
  typedef void* FT_Library;
  typedef signed long FT_Long;
  typedef unsigned long FT_ULong;
  typedef unsigned int FT_UInt;
  typedef signed long FT_Pos;
  typedef signed long FT_Fixed;
  
  typedef struct { FT_Pos x, y; } FT_Vector;
  typedef struct { FT_Pos xMin, yMin, xMax, yMax; } FT_BBox;
  
  typedef struct {
    unsigned int rows;
    unsigned int width;
    int pitch;
    unsigned char* buffer;
    unsigned short num_grays;
    unsigned char pixel_mode;
    char palette_mode;
    void* palette;
  } FT_Bitmap;
  
  typedef struct {
    FT_Pos width, height;
    FT_Pos horiBearingX, horiBearingY, horiAdvance;
    FT_Pos vertBearingX, vertBearingY, vertAdvance;
  } FT_Glyph_Metrics;
  
  typedef struct {
    unsigned short x_ppem, y_ppem;
    FT_Fixed x_scale, y_scale;
    FT_Pos ascender, descender, height, max_advance;
  } FT_Size_Metrics;
  
  typedef struct FT_SizeRec_* FT_Size;
  typedef struct FT_SizeRec_ {
    void* face;
    void* generic_data;
    void* generic_finalizer;
    FT_Size_Metrics metrics;
  } FT_SizeRec;
  
  typedef struct FT_GlyphSlotRec_* FT_GlyphSlot;
  typedef struct FT_GlyphSlotRec_ {
    FT_Library library;
    void* face;
    FT_GlyphSlot next;
    FT_UInt glyph_index;
    void* generic_data;
    void* generic_finalizer;
    FT_Glyph_Metrics metrics;
    FT_Fixed linearHoriAdvance;
    FT_Fixed linearVertAdvance;
    FT_Vector advance;
    int format;
    FT_Bitmap bitmap;
    int bitmap_left;
    int bitmap_top;
  } FT_GlyphSlotRec;
  
  typedef struct FT_FaceRec_* FT_FacePtr;
  typedef struct FT_FaceRec_ {
    FT_Long num_faces, face_index, face_flags, style_flags, num_glyphs;
    char* family_name;
    char* style_name;
    int num_fixed_sizes;
    void* available_sizes;
    int num_charmaps;
    void* charmaps;
    void* generic_data;
    void* generic_finalizer;
    FT_BBox bbox;
    unsigned short units_per_EM;
    short ascender, descender, height;
    short max_advance_width, max_advance_height;
    short underline_position, underline_thickness;
    FT_GlyphSlot glyph;
    FT_Size size;
  } FT_FaceRec;
  
  FT_Error FT_Init_FreeType(FT_Library* alibrary);
  FT_Error FT_Done_FreeType(FT_Library library);
  FT_Error FT_New_Face(FT_Library library, const char* path, FT_Long idx, FT_FacePtr* aface);
  FT_Error FT_Done_Face(FT_FacePtr face);
  FT_Error FT_Set_Pixel_Sizes(FT_FacePtr face, FT_UInt pixel_width, FT_UInt pixel_height);
  FT_Error FT_Load_Char(FT_FacePtr face, FT_ULong char_code, int load_flags);
]]

-- Load FreeType
local ft
for _, name in ipairs({"libfreetype.so.6", "libfreetype.so", "libfreetype.dylib", "freetype"}) do
  local ok, lib = pcall(ffi.load, name)
  if ok then ft = lib; break end
end
if not ft then
  io.stderr:write("Error: Could not load FreeType library.\n")
  os.exit(1)
end

-- Parse arguments
local ttf_file = arg[1]
local font_name = arg[2]
local pixel_size = tonumber(arg[3])

if not ttf_file or not font_name or not pixel_size then
  print("Usage: luajit generate_font.lua <ttf_file> <font_name> <pixel_size>")
  os.exit(1)
end

-- Initialize FreeType
local library = ffi.new("FT_Library[1]")
assert(ft.FT_Init_FreeType(library) == 0, "FT_Init_FreeType failed")

local face = ffi.new("FT_FacePtr[1]")
local err = ft.FT_New_Face(library[0], ttf_file, 0, face)
assert(err == 0, "Could not load font: " .. ttf_file)

err = ft.FT_Set_Pixel_Sizes(face[0], 0, pixel_size)
assert(err == 0, "FT_Set_Pixel_Sizes failed")

local face_rec = ffi.cast("FT_FaceRec*", face[0])
io.stderr:write(string.format("Loaded font: %s %s\n", 
  ffi.string(face_rec.family_name), 
  ffi.string(face_rec.style_name)))

-- Get metrics from size
local size_rec = ffi.cast("FT_SizeRec*", face_rec.size)
local size_metrics = size_rec.metrics
local ascender = math.floor(tonumber(size_metrics.ascender) / 64)
local descender = math.floor(tonumber(size_metrics.descender) / 64)
local line_height = math.floor(tonumber(size_metrics.height) / 64)
local font_height = ascender - descender
local bytes_per_col = math.ceil(font_height / 8)

io.stderr:write(string.format("Font metrics: ascender=%d, descender=%d, height=%d, bytes_per_col=%d\n",
  ascender, descender, font_height, bytes_per_col))

-- Collect glyph data
local glyphs = {}
local bitmap_data = {}
local bitmap_offset = 0
local first_char = 32
local last_char = 126
local FT_LOAD_RENDER = 4

for charcode = first_char, last_char do
  local glyph = {
    charcode = charcode,
    char = string.char(charcode),
    bitmap_offset = bitmap_offset,
    width = 0,
    height = font_height,
    x_offset = 0,
    y_offset = 0,
    x_advance = 0,
    columns = {}
  }
  
  err = ft.FT_Load_Char(face[0], charcode, FT_LOAD_RENDER)
  
  if err == 0 then
    local slot = face_rec.glyph
    local bitmap = slot.bitmap
    local metrics = slot.metrics
    
    local bmp_width = tonumber(bitmap.width)
    local bmp_rows = tonumber(bitmap.rows)
    local bmp_pitch = tonumber(bitmap.pitch)
    
    glyph.x_advance = math.floor(tonumber(metrics.horiAdvance) / 64)
    glyph.x_offset = tonumber(slot.bitmap_left)
    glyph.y_offset = ascender - tonumber(slot.bitmap_top)
    glyph.width = bmp_width
    
    -- Handle space or empty bitmap
    if charcode == 32 or bmp_width == 0 then
      glyph.width = 0
    else
      -- Convert row-based grayscale to column-based monochrome
      for col = 0, bmp_width - 1 do
        local col_bytes = {}
        for b = 1, bytes_per_col do col_bytes[b] = 0 end
        
        for row = 0, bmp_rows - 1 do
          local pixel_val = bitmap.buffer[row * bmp_pitch + col]
          if pixel_val >= 128 then
            local dest_row = row + glyph.y_offset
            if dest_row >= 0 and dest_row < font_height then
              local byte_idx = math.floor(dest_row / 8) + 1
              local bit_idx = dest_row % 8
              col_bytes[byte_idx] = bit.bor(col_bytes[byte_idx], bit.lshift(1, bit_idx))
            end
          end
        end
        
        for b = 1, bytes_per_col do
          table.insert(bitmap_data, col_bytes[b])
          bitmap_offset = bitmap_offset + 1
        end
        table.insert(glyph.columns, col_bytes)
      end
    end
  else
    glyph.x_advance = math.floor(pixel_size / 2)
  end
  
  table.insert(glyphs, glyph)
end

-- Generate C code
local out = io.stdout

out:write(string.format([[
/*
 * %s Font - Bitmap data
 * Generated from: %s
 * Pixel size: %d
 * Height: %d pixels (%d bytes per column)
 */

#include "fonts.h"

]], font_name, ttf_file, pixel_size, font_height, bytes_per_col))

-- Bitmap array
out:write(string.format("static const uint8_t %s%d_bitmap[] = {\n", font_name, pixel_size))
for i, glyph in ipairs(glyphs) do
  if glyph.width > 0 then
    local char_display = glyph.char
    if glyph.charcode == 92 then char_display = "backslash" end
    out:write(string.format("    // %s (%d) - %dpx wide, offset %d\n", 
      char_display, glyph.charcode, glyph.width, glyph.bitmap_offset))
    out:write("    ")
    local items = 0
    for _, col in ipairs(glyph.columns) do
      for b = 1, bytes_per_col do
        out:write(string.format("0x%02X, ", col[b]))
        items = items + 1
        if items >= 12 then out:write("\n    "); items = 0 end
      end
    end
    if items > 0 then out:write("\n") end
  end
end
out:write("};\n\n")

-- Glyph descriptors
out:write(string.format("static const font_glyph_t %s%d_glyphs[] = {\n", font_name, pixel_size))
for _, glyph in ipairs(glyphs) do
  local char_display = glyph.char
  if glyph.charcode == 32 then char_display = "Space" end
  if glyph.charcode == 92 then char_display = "backslash" end
  out:write(string.format("    {%d, %d, %d, %d, %d, %d},  // %s (%d)\n",
    glyph.bitmap_offset, glyph.width, font_height,
    glyph.x_offset, glyph.y_offset, glyph.x_advance,
    char_display, glyph.charcode))
end
out:write("};\n\n")

-- Font struct
out:write(string.format([[
const font_t font_%s_%d = {
    .bitmap = %s%d_bitmap,
    .glyphs = %s%d_glyphs,
    .first_char = %d,
    .last_char = %d,
    .line_height = %d,
    .baseline = %d,
};
]], font_name, pixel_size, font_name, pixel_size, font_name, pixel_size,
    first_char, last_char, line_height, ascender))

ft.FT_Done_Face(face[0])
ft.FT_Done_FreeType(library[0])

io.stderr:write(string.format("Generated %d glyphs, %d bytes of bitmap data\n", #glyphs, #bitmap_data))

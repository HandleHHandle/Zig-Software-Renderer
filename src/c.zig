pub usingnamespace @cImport({
    @cInclude("stdlib.h");
    @cInclude("time.h");
    @cInclude("SDL.h");
    @cDefine("STB_IMAGE_IMPLEMENTATION", "");
    @cDefine("STBI_ONLY_PNG", "");
    @cInclude("misc/stb_image.h");
});

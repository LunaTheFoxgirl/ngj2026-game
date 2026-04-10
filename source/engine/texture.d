module engine.texture;
import engine;
import niobium;
import imagefmt;
import numem;

/**
    A texture
*/
class Texture2D : NuRefCounted {
private:
@nogc:
    NioTexture handle_;

    // Helper that creates a 2D texture handle with no mipmaps.
    NioTexture createTextureHandle(uint width, uint height, NioPixelFormat format) {
        return RENDER_DEVICE.createTexture(NioTextureDescriptor(
            type: NioTextureType.type2D,
            format: format,
            usage: NioTextureUsage.sampled,
            width: width,
            height: height,
            depth: 1,
            levels: 1,
            slices: 1,
        ));
    }

public:

    /**
        Niobium texture handle.
    */
    @property NioTexture handle() => handle_;

    /**
        Width of the texture
    */
    @property uint width() => handle.width;

    /**
        Height of the texture.
    */
    @property uint height() => handle.height;

    /**
        The format of the texture data.
    */
    @property NioPixelFormat format() => handle.format;

    /**
        Constructs a new Texture2D from a file, file must be either
        a TGA, PNG or BMP file.

        Params:
            file = The file to open for texture data
    */
    this(string file) {
        IFImage image = read_image(file, 4, 8);
        if (image.e != 0) {
            throw nogc_new!NuException(IF_ERROR[image.e]);
        }
        this.handle_ = this.createTextureHandle(image.w, image.h, NioPixelFormat.rgba8UnormSRGB);
        handle_.upload(NioRegion3D(0, 0, 0, image.w, image.h, 1), 0, 0, image.buf8, image.w*image.c);
    }

    /**
        Constructs a texture from a file already loaded into memory.
        The file must be either a TGA, PNG or BMP file.

        Params:
            data = The file data.
    */
    this(ubyte[] data) {
        IFImage image = read_image(data, 4, 8);
        if (image.e != 0) {
            throw nogc_new!NuException(IF_ERROR[image.e]);
        }
        this.handle_ = this.createTextureHandle(image.w, image.h, NioPixelFormat.rgba8UnormSRGB);
        handle_.upload(NioRegion3D(0, 0, 0, image.w, image.h, 1), 0, 0, image.buf8, image.w*image.c);
    }

    /**
        Constructs a new empty texture with a given width, height and format.

        Params:
            width =     The width of the texture to create.
            height =    The height od the texture to create.
            format =    The pixel format of the texture.
    */
    this(uint width, uint height, NioPixelFormat format) {
        this.handle_ = this.createTextureHandle(width, height, format);
    }
}
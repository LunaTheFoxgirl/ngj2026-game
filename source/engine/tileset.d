module engine.tileset;
import numem;
import engine.texture;
import inmath;

/**
    A high-level tileset.
*/
class Tileset : NuRefCounted {
private:
@nogc:
    Texture2D texture_;
    rect tileUVArea;

public:

    /**
        The texture of the tileset.
    */
    @property Texture2D texture() => texture_;

    /// Destructor
    ~this() {
        texture_.release();
    }

    /**
        Constructs a new tileset.

        Params:
            texture =   The texture of the tileset
            tileCount = How many tiles are in the tileset on the X and Y axis.
    */
    this(Texture2D texture, vec2u tileCount) {
        this.texture_ = texture.retained;

        vec2 tileSize = vec2(texture.width / tileCount.x, texture.height / tileCount.y);
        this.tileUVArea = rect(0, 0, tileSize.x/cast(float)texture.width, tileSize.y/cast(float)texture.height);
    }

    /**
        Gets the UV coordinates of a given tile in the tilset.

        Params:
            tile = The tile X/Y index.
    */
    rect getTileUV(vec2u tile) {
        return tileUVArea.displaced(vec2(tileUVArea.width, tileUVArea.height)*vec2(tile));
    }
}
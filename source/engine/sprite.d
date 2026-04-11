module engine.sprite;
import engine.texture;
import engine;
import nulib.collections;
import niobium;
import inmath;
import numem;

/**
    Batches multiple sprites into smaller draw calls.

    Sprites a queued up and bucketed until flushed.
    The batch automatically grows its internal allocation to fit the needs of the sprites being uploaded.

    Note:
        A maximum of 2 billion vertices can be drawn in a single pass, this is however
        not recommended for performance reasons.
*/
class SpriteBatch : NuObject {
private:
@nogc:

    // Sets up all the initial state of the batcher.
    void setup(uint initialSpriteCount) {
        static foreach(i; 0..buffers.length) {
            buffers[i] = RENDER_DEVICE.createBuffer(this.makeBatchDescriptor(initialSpriteCount));
        }
        vertices = nu_malloca!SpriteVtx(6*initialSpriteCount);
        buckets = nu_malloca!SpriteBucket(64);
    }

    // Makes a new buffer descriptor for a set amount of sprites.
    NioBufferDescriptor makeBatchDescriptor(uint forSprites) {
        return NioBufferDescriptor(
            usage: NioBufferUsage.vertexBuffer,
            storage: NioStorageMode.privateStorage,
            size: cast(uint)(SpriteVtx.sizeof*6*forSprites)
        );
    }


    //
    //              Buffered Data
    //
    uint align_;
    NioBuffer[2] buffers;
    SpriteVtx[] vertices;
    SpriteBucket[] buckets;

    // Resizes the given buffer to the next alignment up from the given element count.
    void resizeBuffer(ref NioBuffer buffer, size_t toVertices) {
        if (buffer) {
            buffer.release();
        }

        buffer = RENDER_DEVICE.createBuffer(NioBufferDescriptor(
            usage: NioBufferUsage.vertexBuffer,
            storage: NioStorageMode.privateStorage,
            size: cast(uint)(nu_alignup(toVertices, SpriteVtx.sizeof*6*align_))
        ));
    }


    //
    //              State
    //
    bool activeBuffer;
    size_t wptr = 0;     // Write Pointer
    ptrdiff_t bptr = -1; // Bucket Pointer

    // Resets the state of the batch.
    void reset() {
        wptr = 0;
        bptr = -1;
    }

    // Adds a sprite to the current bucket.
    void addSprite(rect area, rect uv, vec4 color) {
        if (wptr+6 > vertices.length) {
            vertices = vertices.nu_resize(vertices.length+6);
        }

        // Push a rectangle from the coordinates in.
        this.vertices[wptr+0] = SpriteVtx(vec2(area.left, area.top),        vec2(uv.left, uv.top),          color);
        this.vertices[wptr+1] = SpriteVtx(vec2(area.left, area.bottom),     vec2(uv.left, uv.bottom),       color);
        this.vertices[wptr+2] = SpriteVtx(vec2(area.right, area.top),       vec2(area.right, area.top),     color);
        this.vertices[wptr+3] = SpriteVtx(vec2(area.right, area.top),       vec2(area.right, area.top),     color);
        this.vertices[wptr+4] = SpriteVtx(vec2(area.left, area.bottom),     vec2(uv.left, uv.bottom),       color);
        this.vertices[wptr+5] = SpriteVtx(vec2(area.right, area.bottom),    vec2(area.right, area.bottom),  color);

        // Increase bucket slice.
        wptr += 6;
        buckets[bptr].end += 6;
    }

    // Flips the active vertex buffer and fills it with the fresh vertex data.
    void flipBuffers() {
        activeBuffer = !activeBuffer;

        // Resize the buffer to fit the data if it's larger than the buffer.
        if (wptr >= buffers[activeBuffer].size) {
            this.resizeBuffer(buffers[activeBuffer], wptr+1);
        }

        // Upload data to the buffer, so that it's ready for rendering.
        buffers[activeBuffer].upload(vertices[0..wptr], 0);
    }

public:

    /// Destructor
    ~this() {
        nu_cleara(buckets);
        nu_cleara(vertices);
        static foreach(i; 0..buffers.length) {
            buffers[i].release();
        }
    }

    /**
        Constructs a new sprite batcher with initial settings.

        Params:
            initialSprites =    The amount of sprites to initially allocate memory for.
            growAlign =         The increments that the sprite batcher's memory can grow by, in sprites.

    */
    this(uint initialSprites = 1024, uint growAlign = 256) {
        this.align_ = growAlign;
        this.setup(initialSprites);
        this.reset();
    }

    /**
        Draws a texture to the sprite batcher.

        Params:
            texture =   The texture to draw.
            area =      The area to draw the texture at.
            uvs =       The UVs to fetch from the texture.
            color =     The multiplicative color to apply to the sprite.
    */
    void draw(Texture2D texture, rect area, rect uvs = rect(0, 0, 1, 1), vec4 color = vec4.one) {

        // Add a new bucket of the data is incompatible.
        if (bptr == -1 || texture !is buckets[bptr].texture) {
            bptr++;
            if (bptr >= buckets.length)
                buckets = buckets.nu_resize(bptr+1);
        }

        this.addSprite(area, uvs, color);
    }

    /**
        Shrinks the memory allocated for this batch to fit the current amount of
        data within the batch.
    */
    void shrinkToFit() {
        this.resizeBuffer(buffers[0], wptr+1);
        this.resizeBuffer(buffers[1], wptr+1);
        this.vertices = vertices.nu_resize(wptr+1);
    }

    /**
        Cancels all drawing operations in the sprite batch.
    */
    void clear() {
        this.reset();
    }

    /**
        Flushes the sprite batcher's contents to the given render command encoder.

        Param:
            pass = The render pass to draw to.
    */
    void flush(NioRenderCommandEncoder pass) {
        this.flipBuffers();
        pass.setVertexBuffer(buffers[activeBuffer], 0, 0);
        foreach(i; 0..bptr) {
            pass.setFragmentTexture(buckets[i].texture, 0);
            pass.draw(NioPrimitive.triangles, cast(uint)buckets[i].start, cast(uint)(buckets[i].end-buckets[i].start));
        }
        this.reset();
    }

}


//
//                  IMPLEMENTATION DETAILS
//
private:

struct SpriteVtx {
    vec2 position;
    vec2 uv;
    vec4 color;
}

/**
    A bucket for sprite drawing commands.
*/
struct SpriteBucket {
    NioTexture texture;
    size_t start;
    size_t end;
}
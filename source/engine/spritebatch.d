module engine.spritebatch;
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

    //
    //          Setup and Global State
    //
    __gshared NioShader sbVertexShader;
    __gshared NioShader sbFragmentShader;
    __gshared const NioRenderPipelineDescriptor sbPipelineDescriptorBase = NioRenderPipelineDescriptor(
        vertexDescriptor: NioVertexDescriptor(
            bindings: [NioVertexBindingDescriptor(NioVertexInputRate.perVertex, SpriteVtx.sizeof)],
            attributes: [
                NioVertexAttributeDescriptor(NioVertexFormat.float2, 0, SpriteVtx.position.offsetof),   //  vec2 position
                NioVertexAttributeDescriptor(NioVertexFormat.float2, 0, SpriteVtx.uv.offsetof),         //  vec2 uv
                NioVertexAttributeDescriptor(NioVertexFormat.float4, 0, SpriteVtx.color.offsetof),      //  vec4 color
            ]
        ),
        colorAttachments: [NioRenderPipelineAttachmentDescriptor(NioPixelFormat.rgba8UnormSRGB, true)]
    );

    // Sets up all the initial state of the batcher.
    void setup(uint initialSpriteCount) {

        // Load base shader(s)
        if (!sbVertexShader) {
            version(OSX) {
                sbVertexShader =    RENDER_DEVICE.createShaderFromNativeSource("sprite.metal", cast(ubyte[])import("sprite.metal"));
                sbFragmentShader =  sbVertexShader.retained();
            } else {
                sbVertexShader =    RENDER_DEVICE.createShaderFromNativeSource("sprite.vert", cast(ubyte[])import("sprite_vert.spv"));
                sbFragmentShader =  RENDER_DEVICE.createShaderFromNativeSource("sprite.frag", cast(ubyte[])import("sprite_frag.spv"));
            }
        }
        
        this.resizeBuffer(buffers[0], initialSpriteCount);
        this.resizeBuffer(buffers[1], initialSpriteCount);
        this.resizeUniforms(uniformBuffer, mat4.sizeof);
        vertices = nu_malloca!SpriteVtx(6*initialSpriteCount);
        buckets = nu_malloca!SpriteBucket(64);
        this.sampler = RENDER_DEVICE.createSampler(NioSamplerDescriptor(
            NioSamplerWrap.repeat, 
            NioSamplerWrap.repeat, 
            NioSamplerWrap.repeat, 
            NioMinMagFilter.nearest, 
            NioMinMagFilter.nearest, 
            NioMipFilter.none,
        ));

        // Setup pipeline for this batch.
        this.basePipeline = RENDER_DEVICE.createRenderPipeline(NioRenderPipelineDescriptor(
            vertexFunction: sbVertexShader.getFunction("vertex_main"),
            fragmentFunction: sbFragmentShader.getFunction("fragment_main"),
            vertexDescriptor: cast(NioVertexDescriptor)sbPipelineDescriptorBase.vertexDescriptor,
            colorAttachments: cast(NioRenderPipelineAttachmentDescriptor[])sbPipelineDescriptorBase.colorAttachments
        ));
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
    NioBuffer uniformBuffer;
    SpriteVtx[] vertices;
    SpriteBucket[] buckets;
    NioRenderPipeline[] pipelines;
    NioRenderPipeline basePipeline;
    NioSampler sampler;

    // Resizes the given buffer to the next alignment up from the given element count.
    void resizeBuffer(ref NioBuffer buffer, size_t toVertices) {
        if (buffer) {
            buffer.release();
        }

        size_t targetSize = nu_alignup(toVertices, 6*align_);
        if (targetSize > vertices.length)
            vertices = vertices.nu_resize(targetSize);

        buffer = RENDER_DEVICE.createBuffer(NioBufferDescriptor(
            usage: NioBufferUsage.vertexBuffer,
            storage: NioStorageMode.privateStorage,
            size: cast(uint)(SpriteVtx.sizeof*targetSize)
        ));
    }

    // Resize uniform storage.
    void resizeUniforms(ref NioBuffer buffer, size_t length) {
        if (buffer) {
            buffer.release();
        }

        buffer = RENDER_DEVICE.createBuffer(NioBufferDescriptor(
            usage: NioBufferUsage.uniformBuffer,
            storage: NioStorageMode.privateStorage,
            size: cast(uint)nu_alignup(16, length)
        ));
    }


    //
    //              State
    //
    bool activeBuffer;
    size_t wptr = 0;     // Write Pointer
    ptrdiff_t bptr = -1; // Bucket Pointer
    ptrdiff_t pptr = -1;

    // Resets the state of the batch.
    void reset() {
        wptr = 0;
        bptr = -1;
        pptr = -1;
    }

    // Adds a sprite to the current bucket.
    void addSprite(rect area, rect uv, vec4 color, vec2 origin = vec2(0, 0), float rotation = 0) {
        if (wptr+6 > vertices.length)
            vertices = vertices.nu_resize(nu_alignup(wptr+6, 6*align_));

        // Size of the sprite in pixel coordinates.
        vec2 size = vec2(area.width, area.height);

        // Base vertices.
        vec2 tl = vec2(area.left, area.top);
        vec2 bl = vec2(area.left, area.bottom);
        vec2 tr = vec2(area.right, area.top);
        vec2 br = vec2(area.right, area.bottom);

        // Make rotated vertices.
        if (origin != vec2(0, 0)) {
            mat3 rotM = mat3.zRotation(rotation);
            tl = ((rotM * vec3(-origin.x, -origin.y, 0)).xy * size) + area.corner;
            bl = ((rotM * vec3(-origin.x, +origin.y, 0)).xy * size) + area.corner;
            tr = ((rotM * vec3(+origin.x, -origin.y, 0)).xy * size) + area.corner;
            br = ((rotM * vec3(+origin.x, +origin.y, 0)).xy * size) + area.corner;
        }

        // Push a rectangle from the coordinates in.
        this.vertices[wptr+0] = SpriteVtx(tl,   vec2(uv.left,   uv.top),        color);
        this.vertices[wptr+1] = SpriteVtx(bl,   vec2(uv.left,   uv.bottom),     color);
        this.vertices[wptr+2] = SpriteVtx(tr,   vec2(uv.right,  uv.top),        color);
        this.vertices[wptr+3] = SpriteVtx(tr,   vec2(uv.right,  uv.top),        color);
        this.vertices[wptr+4] = SpriteVtx(bl,   vec2(uv.left,   uv.bottom),     color);
        this.vertices[wptr+5] = SpriteVtx(br,   vec2(uv.right,  uv.bottom),     color);

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

    // Evaluates whether a new bucket needs to be created, 
    void beginSpritePush(NioTexture forTexture) {
        auto currentPipeline = this.getCurrentPipeline();
        
        // New frame, add initial bucket.
        if (bptr == -1) {
            this.addBucket(forTexture, currentPipeline);
            return;
        }

        // Add new bucket if the pipeline is incompatible.
        if (buckets[bptr].pipeline !is currentPipeline) {
            this.addBucket(forTexture, currentPipeline);
            return;
        }

        // Add a new bucket if the texture is incompatible.
        if (forTexture !is buckets[bptr].texture) {
            this.addBucket(forTexture, currentPipeline);
            return;
        }
    }

    // Adds a new bucket.
    void addBucket(NioTexture texture, NioRenderPipeline pipeline) {
        if (++bptr >= buckets.length) {
            buckets = buckets.nu_resize(bptr+1);
        }

        // Set bucket data.
        buckets[bptr].texture = texture;
        buckets[bptr].pipeline = pipeline;
        buckets[bptr].start = wptr;
        buckets[bptr].end = wptr;
    }

    NioRenderPipeline getCurrentPipeline() {
        return pptr >= 0 ? pipelines[pptr] : basePipeline;
    }

public:

    /// Destructor
    ~this() {
        nu_cleara(buckets);
        nu_cleara(vertices);
        nu_cleara(pipelines);
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
        Pushes the given shader pipeline to the pipeline stack.

        Params:
            pipeline = The pipeline to push onto the pipeline stack.
    */
    void beginPipeline(NioRenderPipeline pipeline) {
        if (++pptr > pipelines.length)
            pipelines = pipelines.nu_resize(pptr+1);

        pipelines[pptr] = pipeline;
    }

    /**
        Pops a pipeline from the pipeline stack.
    */
    void endPipeline() {
        pptr--;
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
        this.beginSpritePush(texture.handle);
        this.addSprite(area, uvs, color);
    }

    /**
        Draws a texture to the sprite batcher.

        Params:
            texture =   The texture to draw.
            area =      The area to draw the texture at.
            origin =    Origin of rotation.
            uvs =       The UVs to fetch from the texture.
            rotation =  Rotation delta (radians)
            color =     The multiplicative color to apply to the sprite.
    */
    void draw(Texture2D texture, rect area, vec2 origin = vec2(0, 0), rect uvs = rect(0, 0, 1, 1), float rotation = 0, vec4 color = vec4.one) {
        this.beginSpritePush(texture.handle);
        this.addSprite(area, uvs, color, origin, rotation);
    }

    /**
        Shrinks the memory allocated for this batch to fit the current amount of
        data within the batch.
    */
    void shrinkToFit() {
        this.resizeBuffer(buffers[0], wptr+1);
        this.resizeBuffer(buffers[1], wptr+1);
        this.vertices = vertices.nu_resize(wptr+1);
        this.pipelines = pipelines.nu_resize(pptr+1);
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
            pass =      The render pass to draw to.
    */
    void flush(NioRenderCommandEncoder pass, mat4 viewProjection) {
        this.flipBuffers();
        this.uniformBuffer.upload(viewProjection.transposed(), 0);
        
        foreach(i; 0..bptr+1) {
            pass.setPipeline(buckets[i].pipeline);
            pass.setVertexBuffer(buffers[activeBuffer], 0, 0);
            pass.setVertexBuffer(uniformBuffer, 0, 1);
            pass.setFragmentTexture(buckets[i].texture, 0);
            pass.setFragmentSampler(sampler, 0);
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
    NioRenderPipeline pipeline;
    NioTexture texture;
    size_t start;
    size_t end;
}
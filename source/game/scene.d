module game.scene;
import game.entity;
import game.camera;
import game.scrungly;
import inmath.color;
import inmath;
import engine;
import std.random;

enum BORDER_SIZE = 500;

/**
    A collection of tiles and entities that are currently active in the game.
*/
class Scene {
private:
    long lastTime;
    Entity[] entities;
    SpriteBatch spriteBatch;

    void focusCamera() {
        uint scrunglies = 0;
        vec2 accum = vec2(0, 0);
        foreach(entity; entities) {
            if (auto scrungly = cast(Scrungly)entity) {
                accum += scrungly.drawPosition;
                scrunglies++;
            }
        }

        camera.position = vec2(accum.x / scrunglies, accum.y / scrunglies);
    }

    // Arena border
    NioRenderPipeline borderPipeline;
    NioBuffer borderVbo;
    NioBuffer borderUbo;
    vec4 borderColor = vec4(1, 1, 1, 1);

    void createBorder() {
        
        // Vertex Buffer
        borderVbo = RENDER_DEVICE.createBuffer(NioBufferDescriptor(
            usage: NioBufferUsage.vertexBuffer,
            storage: NioStorageMode.privateStorage,
            vec2.sizeof*8
        ));
        borderVbo.upload([

            // TL->BL
            vec2(-BORDER_SIZE, -BORDER_SIZE),
            vec2(-BORDER_SIZE, BORDER_SIZE),

            // BL->BR
            vec2(-BORDER_SIZE, BORDER_SIZE),
            vec2(BORDER_SIZE, BORDER_SIZE),

            // BR->TR
            vec2(BORDER_SIZE, BORDER_SIZE),
            vec2(BORDER_SIZE, -BORDER_SIZE),

            // TR->TL
            vec2(BORDER_SIZE, -BORDER_SIZE),
            vec2(-BORDER_SIZE, -BORDER_SIZE),
        ], 0);

        // Uniform buffer
        borderUbo = RENDER_DEVICE.createBuffer(NioBufferDescriptor(
            usage: NioBufferUsage.uniformBuffer,
            storage: NioStorageMode.privateStorage,
            BorderData.sizeof
        ));

        auto shader = RENDER_DEVICE.createShaderFromNativeSource("border.metal", cast(ubyte[])import("border.metal"));

        // Shader
        borderPipeline = RENDER_DEVICE.createRenderPipeline(NioRenderPipelineDescriptor(
            shader.getFunction("vertex_main"),
            shader.getFunction("fragment_main"),
            NioVertexDescriptor(
                [NioVertexBindingDescriptor(NioVertexInputRate.perVertex, vec2.sizeof)],
                [NioVertexAttributeDescriptor(NioVertexFormat.float2, 0, 0)]
            ),
            [NioRenderPipelineAttachmentDescriptor(NioPixelFormat.bgra8UnormSRGB, true)]
        ));
    }

    void updateBorder() {
        borderColor = vec4(hsv2rgb(vec3((sin(cast(float)getTimeTicks()*0.001)+1)/2, 1, 1)), 1);
    }
public:

    /**
        The camera of the scene.
    */
    Camera camera;

    /**
        Constructs a new scene.
    */
    this(SpriteBatch spriteBatch) {
        this.spriteBatch = spriteBatch;
        this.createBorder();

        foreach(i; 0..20) {
            this.spawn(new Scrungly(this, vec2(uniform(-100, 100), uniform(-100, 100))));

        }
    }

    /**
        Spawns a given entitiy into the world.
    */
    void spawn(Entity entity) {
        entities ~= entity;
    }

    /**
        Updates the scene and all the entities within.
    */
    void update() {
        long currentTime = getTimeTicks();
        float deltaTime = cast(float)(currentTime-lastTime) * 0.001;

        // Clean up dead entities
        import std.algorithm.mutation : remove;
        foreach_reverse(i; 0..entities.length) {
            if (!entities[i].isAlive)
                entities = entities.remove(i);
        }

        // Update entities.
        foreach(entity; entities)
            entity.update(deltaTime);

        // Post-update entities.
        foreach(entity; entities)
            entity.postUpdate(deltaTime);

        this.focusCamera();
        this.updateBorder();
        
        lastTime = currentTime;
    }

    /**
        Draws the scene to the given command buffer.

        Params:
            target =    Texture target to render to.
            cmdbuffer = Command buffer to render to.
    */
    void draw(NioTexture target, NioCommandBuffer cmdbuffer, NioColor clearColor = NioColor(0, 0, 0, 1)) {
        foreach(entity; entities)
            entity.draw(spriteBatch);
        
        camera.update(NioExtent2D(1920, 1080));

        mat4 viewProjection = mat4.orthographic01(0, 1920, 1080, 0, 0.1, 1000) * camera.matrix;
        borderUbo.upload([BorderData(viewProjection.transposed(), borderColor)], 0);

        auto pass = cmdbuffer.beginRenderPass(NioRenderPassDescriptor([NioColorAttachmentDescriptor(target, 0, 0, 0, NioLoadAction.clear, NioStoreAction.store, clearColor)]));
        spriteBatch.flush(pass, viewProjection);


        // Draw border around level.
        pass.setPipeline(borderPipeline);
        pass.setVertexBuffer(borderVbo, 0, 0);
        pass.setVertexBuffer(borderUbo, 0, 1);
        pass.setFragmentBuffer(borderUbo, 0, 1);
        pass.draw(NioPrimitive.lines, 0, 8);
        pass.endEncoding();
    }
}

struct BorderData {
    mat4 viewProjection;
    vec4 color;
}
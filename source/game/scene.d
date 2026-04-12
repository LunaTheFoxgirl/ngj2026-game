module game.scene;
import game.entity;
import game.camera;
import game.scrungly;
import inmath.color;
import inmath;
import engine;
import std.random;
import game.scrongler;
import game.orb;

enum BORDER_SIZE = 500;

enum ORB_COUNT = 25;

enum VIEWPORT_WIDTH = 1920;
enum VIEWPORT_HEIGHT = 1080;

enum TIME_TO_SCRONGLER = 60*5;

/**
    A collection of tiles and entities that are currently active in the game.
*/
class Scene {
private:
    long lastTime;
    Entity[] entities;
    SpriteBatch spriteBatch;

    void focusCamera(float deltaTime) {
        uint scrunglies = 0;
        vec2 accum = vec2(0, 0);
        foreach(entity; entities) {
            if (auto scrungly = cast(Scrungly)entity) {
                accum += scrungly.drawPosition;
                scrunglies++;
            }
        }

        vec2 camTarget = vec2(accum.x / scrunglies, accum.y / scrunglies);
        camera.position = dampen(
            camera.position, 
            camTarget, 
            deltaTime
        );
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

    // Mechanics
    float spawnTimer = 0;
    Scrongler boss;

    void updateBaseMechanics(float delta) {

        // You have 5 minutes to get scrunglies for your army.
        if (spawnTimer < TIME_TO_SCRONGLER) {
            spawnTimer += delta;
            this.ensureOrbs();
            return;
        }

        // The boss has arrived!!
        if (!boss) {
            this.destroyOrbs();
            boss = new Scrongler(this, vec2(0, 0));
            this.spawn(boss);
        }
    }

    void ensureOrbs() {
        uint orbs = 0;
        foreach(entity; entities) {
            if (cast(Orb)entity)
                orbs++;
        }

        // Spawn needed orb count.
        while(orbs++ < ORB_COUNT)
            this.spawn(new Orb(this, vec2(uniform(-BORDER_SIZE, BORDER_SIZE), uniform(-BORDER_SIZE, BORDER_SIZE))));
    }

    void destroyOrbs() {
        import std.algorithm.mutation : remove;
        foreach_reverse(i; 0..entities.length) {
            if (cast(Orb)entities[i]) {
                entities[i].forceKill();
                entities = entities.remove(i);
            }
        }
    }

public:

    /**
        The camera of the scene.
    */
    Camera camera;

    /**
        All currently alive entities.
    */
    @property Entity[] allEntities() => entities;

    /**
        Constructs a new scene.
    */
    this(SpriteBatch spriteBatch) {
        this.spriteBatch = spriteBatch;
        this.createBorder();

        this.spawn(new Scrungly(this, vec2(0, 0)));
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

        // Update the border and base mechanics
        this.updateBorder();
        this.updateBaseMechanics(deltaTime);

        // Update entities.
        foreach(entity; entities)
            entity.update(deltaTime);

        // Post-update entities.
        foreach(entity; entities)
            entity.postUpdate(deltaTime);

        this.focusCamera(deltaTime);
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
        
        camera.update(NioExtent2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT));
        borderUbo.upload([BorderData(camera.matrix.transposed(), borderColor)], 0);

        auto pass = cmdbuffer.beginRenderPass(NioRenderPassDescriptor([NioColorAttachmentDescriptor(target, 0, 0, 0, NioLoadAction.clear, NioStoreAction.store, clearColor)]));
            spriteBatch.flush(pass, camera.matrix);

            // Draw border around level.
            pass.setPipeline(borderPipeline);
            pass.setVertexBuffer(borderVbo, 0, 0);
            pass.setVertexBuffer(borderUbo, 0, 1);
            pass.setFragmentBuffer(borderUbo, 0, 1);
            pass.draw(NioPrimitive.lines, 0, 8);
        pass.endEncoding();
    }

    void newRound() {
        spawnTimer = 0;
    }

    /**
        Gets entity at position.

        Params:
            position = The position to get the entity at

        Returns:
            The entity at that position or $(D null).
    */
    Entity getEntityAt(vec2 position) {
        foreach(entity; entities) {
            if (entity.hitbox.intersects(position))
                return entity;
        }
        return null;
    }
}

struct BorderData {
    mat4 viewProjection;
    vec4 color;
}
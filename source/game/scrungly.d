module game.scrungly;
import engine;
import game;
import inmath.color;
import std.random;
import std.stdio;

/**
    A player controller scrungly.
*/
class Scrungly : Entity {
private:
    Texture2D texture;
    vec2 target = vec2(0, 0);
    vec4 color;

    float animSpeed = 0;
    float animTime = 0;
    float rotation = 0;

public:

    /// Destructor
    ~this() {
        texture.release();
    }

    /**
        Constructs a new player.
    */
    this(Scene scene, vec2 spawnPoint) {
        super(scene);
        this.texture = nogc_new!Texture2D("assets/sprites/scrungly.png");
        this.position = spawnPoint;
        this.target = spawnPoint;

        // Give each scrungly a random color.
        this.color = vec4(hsv2rgb(vec3(uniform01(), 1, 1)), 1);
    }

    /**
        Updates the entity.

        Params:
            delta = time since last frame.
    */
    override void update(float delta) {
        
        // Get target direction and velocity.
        vec2 targetDir = (target - position).normalized();
        vec2 velocity = vec2(round(targetDir.x), round(targetDir.y));

        animSpeed = dampen(animSpeed, abs(velocity.length())*10*delta, delta);
        position += velocity;
    }

    /**
        Post-updates the entity.

        Params:
            delta = Time since last frame.
    */
    override void postUpdate(float delta) {
        animTime += animSpeed;

        rotation = lerp(
            0,
            lerp(radians(-10), radians(10), (sin(animTime)+1)/2.0),
            clamp(animSpeed*10, 0, 1)
        );

        if (Mouse.isClicked(MouseButton.BUTTON_LEFT)) {
            vec2 windowCenter = (GAME_WINDOW.size / 2);
            vec2 mouseCenterRel = Mouse.position - windowCenter;
            vec2 targetSubpixel = (scene.camera.position + mouseCenterRel);

            target = vec2(
                round(targetSubpixel.x)+uniform(-64, 64), 
                round(targetSubpixel.y)+uniform(-64, 64)
            );
        }
    }

    /**
        Draws the entity onto the given sprite batch.

        Params:
            spriteBatch = The sprite batch to render the entity to.
    */
    override void draw(SpriteBatch spriteBatch) {
        spriteBatch.draw(texture, rect(drawPosition.x, drawPosition.y, texture.width, texture.height), vec2(0.5, 0.5), rect(0, 0, 1, 1), rotation, color);
    }
}
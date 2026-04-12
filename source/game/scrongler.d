module game.scrongler;
import engine;
import game;
import inmath.color;
import std.random;
import std.stdio;

/**
    The big bad.
*/
class Scrongler : Entity {
private:
    Texture2D texture;

    float ftAccum = 0;
    int frame = 0;

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
        this.texture = nogc_new!Texture2D("assets/sprites/scrongler.png");
    }

    /**
        Updates the entity.

        Params:
            delta = time since last frame.
    */
    override void update(float delta) {
        
    }

    /**
        Post-updates the entity.

        Params:
            delta = Time since last frame.
    */
    override void postUpdate(float delta) {

        // Scuffed animation.
        ftAccum += delta;
        if (ftAccum > 0) {
            ftAccum = 0;
            frame++;
        }
        frame %= 2;
    }

    /**
        Draws the entity onto the given sprite batch.

        Params:
            spriteBatch = The sprite batch to render the entity to.
    */
    override void draw(SpriteBatch spriteBatch) {
        spriteBatch.draw(
            texture, 
            rect(drawPosition.x, drawPosition.y, texture.width/2, texture.height), 
            vec2(0.5, 0.5), 
            rect(0.5*frame, 0, 0.5, 1), 
            0, 
            vec4(1, 1, 1, 1)
        );
    }
}
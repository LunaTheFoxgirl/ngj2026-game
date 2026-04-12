module game.orb;
import game.scrungly;
import std.random;
import engine;
import game;

/**
    An orb.
*/
class Orb : Entity {
private:
    __gshared Texture2D texture;

    float dmgTimer = 0;
    float ftAccum = 0;
    int frame = 0;

    vec2 shake = vec2(0, 0);

protected:

    override void onDeath() {
        scene.spawn(new Scrungly(scene, position));
    }

    override void onDamaged(int damage) {
        dmgTimer = 1;
    }

public:

    /**
        The hitbox of the entity.
    */
    override @property rect hitbox() => rect(position.x-(texture.width/2), position.y-(texture.height/2), texture.width, texture.height);

    /**
        Constructs a new player.
    */
    this(Scene scene, vec2 spawnPoint) {
        super(scene);
        
        this.position = spawnPoint;
        if (!texture)
            this.texture = nogc_new!Texture2D("assets/sprites/void_orb.png");
    }

    /**
        Updates the entity.

        Params:
            delta = time since last frame.
    */
    override void update(float delta) {

        // Handle damage
        if (dmgTimer > 0) {
            dmgTimer = max(0, dmgTimer-delta);
        }

        // Scuffed animation.
        ftAccum += delta;
        if (ftAccum > 0.5) {
            ftAccum = 0;
            frame++;
        }
        frame %= 5;

        shake = lerp(
            vec2(0, 0),
            vec2(uniform01(), uniform01())*8,
            dmgTimer
        );
    }

    /**
        Post-updates the entity.

        Params:
            delta = Time since last frame.
    */
    override void postUpdate(float delta) {
    }

    /**
        Draws the entity onto the given sprite batch.

        Params:
            spriteBatch = The sprite batch to render the entity to.
    */
    override void draw(SpriteBatch spriteBatch) {
        float fSize = 1.0/4;

        spriteBatch.draw(
            texture, 
            rect(drawPosition.x+shake.x, drawPosition.y+shake.y, texture.width/4, texture.height), 
            vec2(0.5, 0.5), 
            rect(fSize*frame, 0, fSize, 1), 
            0, 
            vec4(1, 1, 1, 1)
        );
    }
}
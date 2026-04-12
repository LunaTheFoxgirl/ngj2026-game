module game.scrongler;
import game.scrungly;
import engine;
import game;
import inmath.color;
import std.random;
import std.stdio;

enum SCRONGLER_ATTACK_RATE = 1.0;

enum SCRONGLER_HEALTH = 5_000;

/**
    The big bad.
*/
class Scrongler : Entity {
private:
    __gshared Texture2D texture;
    __gshared uint scronglerMaxHealth = SCRONGLER_HEALTH;

    Entity target;
    vec2 targetPosition = vec2(0, 0);

    float attackTimer = 0;
    float dmgTimer = 0;

    float ftAccum = 0;
    int frame = 0;

protected:

    override void onDeath() {
        scene.newRound();
    }


    /**
        Callback invoked when the entity is damaged.

        Params:
            damage = The amount of damage that was taken.
    */
    override void onDamaged(int damage) {
        this.dmgTimer = 1;
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

        if (!texture)
            this.texture = nogc_new!Texture2D("assets/sprites/scrongler.png");

        this.hitpoints = scronglerMaxHealth;
        scronglerMaxHealth *= 2;
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

        if (target) {
        
            // Get target direction and velocity.
            vec2 targetDir = (target.hitbox.center - targetPosition).normalized();
            vec2 velocity = vec2(round(targetDir.x), round(targetDir.y)) * 0.5;

            targetPosition += velocity;

            // Cursed damaging logic.
            if (abs(hitbox.center.distance(target.hitbox.center)) < 32) {
                attackTimer += delta;

                if (attackTimer > SCRONGLER_ATTACK_RATE) {
                    target.damage(10);
                    attackTimer = 0;
                }
            }

            if (target.health <= 0)
                target = null;
            
            return;
        }

        // Find another scrungly to target.
        foreach(entity; scene.allEntities) {
            if (cast(Scrungly)entity)
                this.target = entity;
        }
    }

    /**
        Post-updates the entity.

        Params:
            delta = Time since last frame.
    */
    override void postUpdate(float delta) {

        // Scuffed animation.
        ftAccum += delta;
        if (ftAccum > 0.5) {
            ftAccum = 0;
            frame++;
        }
        frame %= 2;

        position = targetPosition;
        position.y += sin(getTimeTicks()*0.001)*16;
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
            lerp(vec4(1, 1, 1, 0.5), vec4(1, 0, 0, 0.5), dmgTimer)
        );
    }
}
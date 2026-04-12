module game.entity;
import engine;
import game.scene;

/**
    An entity within the game.
*/
abstract class Entity {
private:
    Scene scene_;

protected:
    /**
        Hitpoints of the entity.
    */
    int hitpoints = 100;

    /**
        Position of the entity, in pixels.
    */
    vec2 position = vec2(0, 0);

    /**
        Base constructor of entities.

        Params:
            scene = The owning scene.
    */
    this(Scene scene) {
        this.scene_ = scene;
    }

    /**
        Callback invoked when the entity dies.
    */
    void onDeath() { }

    /**
        Callback invoked when the entity is damaged.

        Params:
            damage = The amount of damage that was taken.
    */
    void onDamaged(int damage) { }
    
public:

    /**
        Scene this entity belongs to.
    */
    final @property Scene scene() => scene_;

    /**
        The position that the entity is to be drawn at.
    */
    final @property vec2 drawPosition() => vec2(round(position.x), round(position.y));

    /**
        The hitbox of the entity.
    */
    abstract @property rect hitbox();

    /**
        Whether the entity is alive.
    */
    final @property bool isAlive() => hitpoints > 0;

    /**
        Health of the entity.
    */
    final @property int health() => hitpoints;

    /**
        Updates the entity.

        Params:
            delta = Time since last frame.
    */
    abstract void update(float delta);

    /**
        Post-updates the entity.

        Params:
            delta = Time since last frame.
    */
    abstract void postUpdate(float delta);

    /**
        Draws the entity onto the given sprite batch.

        Params:
            spriteBatch = The sprite batch to render the entity to.
    */
    abstract void draw(SpriteBatch spriteBatch);

    /**
        Moves the entity to a given coordinate.

        Params:
            to = The position to move the entity to.
    */
    final void move(vec2 to) {
        this.position = to;
    }

    /**
        Damages the entity.

        Params:
            attack = the attack power of the entity.
    */
    final void damage(int attack) {
        if (hitpoints > 0) {
            int beforeHP = hitpoints;
            this.hitpoints -= attack;
            this.onDamaged(attack);

            if (beforeHP > 0 && hitpoints <= 0)
                this.onDeath();
        }
    }

    /**
        Forcefully kills an entity.
    */
    final void forceKill() {
        this.hitpoints = -1000;
    }
}
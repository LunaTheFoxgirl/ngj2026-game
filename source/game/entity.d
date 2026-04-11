module game.entity;
import engine.spritebatch;

/**
    An entity within the game.
*/
abstract class Entity {

    /**
        Whether the entity is alive.
    */
    abstract @property bool isAlive();

    /**
        Updates the entity.
    */
    abstract void update(float delta);

    /**
        Draws the entity onto the given sprite batch.

        Params:
            spriteBatch = The sprite batch to render the entity to.
    */
    abstract void draw(SpriteBatch spriteBatch);
}
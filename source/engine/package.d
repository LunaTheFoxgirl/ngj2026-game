/**
    Root engine module.

    Authors:
        Luna Nielsen
*/
module engine;
import niobium;
import sdl;

public import engine.window;
public import engine.texture;
public import engine.spritebatch;
public import numem;

/**
    The global rendering device used to render throughout the lifetime of the game.
*/
__gshared NioDevice RENDER_DEVICE;

/**
    Initializes the engine.
*/
void initializeEngine() @nogc{
    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD | SDL_INIT_HAPTIC);
    RENDER_DEVICE = NioDevice.systemDevices[0];
}

/**
    Shuts down the engine.
*/
void shutdownEngine() @nogc {

}
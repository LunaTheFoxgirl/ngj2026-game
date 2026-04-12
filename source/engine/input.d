/**
    Input handling subsystem.
*/
module engine.input;
import sdl.keyboard;
import sdl.mouse;
import inmath;
import numem;

/// A key on the keyboard.
alias Key = SDL_Scancode;

/**
    A logical text input device, generally a keyboard.
*/
static class Keyboard : NuObject {
private:
static:
@nogc:
    __gshared bool[] prevState = null;
    __gshared bool[] currState = null;

    static const(bool)[] getKeyboardState() {
        int keyCount;
        const(bool)* keys = SDL_GetKeyboardState(&keyCount);
        return keys[0..keyCount];
    }
public:

    /**
        Updates the keyboard info.
    */
    void update() {
        if (currState.length == 0) {

            int keyCount;
            cast(void)SDL_GetKeyboardState(&keyCount);
            
            // First iteration
            currState = nu_malloca!bool(keyCount);
            prevState = nu_malloca!bool(keyCount);
        }

        auto cstate = getKeyboardState();
        prevState[0..$] = currState[0..$];
        currState[0..$] = cstate[0..$];
    }

    /**
        Gets whether the given $(D Key) is down.

        Params:
            key = the key to check.
        
        Returns:
            $(D true) if the key is down,
            $(D false) otherwise.
    */
    bool wasKeyDown(Key key) {
        return prevState[key];
    }
    
    /**
        Gets whether the given $(D Key) is down.

        Params:
            key = the key to check.
        
        Returns:
            $(D true) if the key is down,
            $(D false) otherwise.
    */
    bool isKeyDown(Key key) {
        return currState[key];
    }

    /**
        Gets whether the given $(D Key) was pressed this frame.

        This function is only fired once.

        Params:
            key = the key to check.
        
        Returns:
            $(D true) if the key is down,
            $(D false) otherwise.
    */
    bool isKeyPressed(Key key) {
        return !prevState[key] && currState[key];
    }

    /**
        Gets whether the given $(D Key) was released
        this frame.

        Params:
            key = the key to check.
        
        Returns:
            $(D true) if the key is down,
            $(D false) otherwise.
    */
    bool isKeyReleased(Key key) {
        return prevState[key] && !currState[key];
    }
}

alias MouseButton = SDL_MouseButtonFlags;

/**
    A logical pointing device, generally a mouse.
*/
static class Mouse : NuObject {
private:
static:
@nogc:
    __gshared float rmx = 0, rmy = 0;
    __gshared float pmx = 0, pmy = 0;
    __gshared float mx = 0, my = 0;
    __gshared MouseButton pbuttons;
    __gshared MouseButton buttons;

public:

    /**
        The amount the mouse moved this frame.
    */
    @property vec2 movement() => vec2(rmx, rmy);

    /**
        Position of the mouse relative to the window.
    */
    @property vec2 position() => vec2(mx, my);

    /**
        Updates the mouse state
    */
    void update() {
        this.pbuttons = buttons;
        this.pmx = mx;
        this.pmy = my;
        this.buttons = SDL_GetMouseState(&mx, &my);
        cast(void)SDL_GetRelativeMouseState(&rmx, &rmy);
    }

    /**
        Gets whether the $(D MouseButton) has been clicked this frame.

        Params:
            button = the mouse button to check.
        
        Returns:
            $(D true) if the button was clicked,
            $(D false) otherwise.
    */
    bool isClicked(MouseButton button) {
        return !(pbuttons & button) & (buttons & button);
    }

    /**
        Gets whether the $(D MouseButton) has been released this frame.

        Params:
            button = the mouse button to check.
        
        Returns:
            $(D true) if the button was released,
            $(D false) otherwise.
    */
    bool isReleased(MouseButton button) {
        return (pbuttons & button) & !(buttons & button);
    }

    /**
        Gets whether the given mouse button was being pressed the last frame.

        Params:
            button = the mouse button to check.
        
        Returns:
            $(D true) if the button was being pressed,
            $(D false) otherwise.
    */
    bool wasPressed(MouseButton button) {
        return cast(bool)(pbuttons & button);
    }

    /**
        Gets whether the given mouse button is being pressed.

        Params:
            button = the mouse button to check.
        
        Returns:
            $(D true) if the button is being pressed,
            $(D false) otherwise.
    */
    bool isPressed(MouseButton button) {
        return cast(bool)(buttons & button);
    }

}
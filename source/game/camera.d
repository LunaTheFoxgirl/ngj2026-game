module game.camera;
import engine;

/**
    The camera of a scene.
*/
struct Camera {
private:
    mat4 matrix_ = mat4.identity;

public:

    /**
        Position of the camera
    */
    vec2 position = vec2(0, 0);

    /**
        Scale of the camera.
    */
    float scale = 5;

    /**
        The camera matrix.
    */
    @property mat4 matrix() => matrix_;

    /**
        Update's the camera's matrix.
    */
    void update(NioExtent2D viewport) {
        this.matrix_ = 
            mat4.translation((viewport.width/2), (viewport.height/2), 0) *
            mat4.scaling(scale, scale, 1) *
            mat4.translation(position.x, position.y, 0).inverse();
    }
}
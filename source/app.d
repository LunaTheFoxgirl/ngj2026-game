import engine;
import game;

void main() {
	// Setup main window and its surface.
	initializeEngine();
	Scene scene = new Scene(RENDER_BATCH);

	while(Window.windows.length > 0) {
		updateEngineCore();
		if (auto drawable = GAME_SURFACE.next()) {
			if (auto buffer = RENDER_QUEUE.fetch()) {
				scene.update();
				scene.draw(drawable.texture, buffer);

				buffer.present(drawable);
				RENDER_QUEUE.commit(buffer);
				buffer.await();
			}
		}
	}
	shutdownEngine();
}
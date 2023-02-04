# The Cave Game - Caravan

This project is a dungeon exploration game made using procedural level generation. It procedurally generates room quantity, locations, connections, tile decorations, platorms, and enemies. It is made using the Godot game engine.

### Demo

In Caravan you collect berries all while trying to escape deeper into the caves by finding the exit door. But watch out! There are enemies in the cave that have corrosive slime. Good news- you are also a corrosive slime, but an extra cool version as you've figured out how to shoot slime as to clear the way for success. Defeat enemies, collect berries, and see how far you can travel!

https://user-images.githubusercontent.com/97637778/216750694-d3950c5c-aa46-4783-a978-ba9da43100f9.mov

### Generation

The generation is highly customizable. Room number, room size, and vertical or horizontal generation preference can be set before generation. Below is a video demo of the step by step process of generation. Firstly, a large amount of physics bodies are spawned in the exact same location, and as such collide with one another to create a random pattern. Then, some bodies are randomly removed, and the A* pathfinding algorithm is used to connect the rooms. This can be repeated many times until a suitable generation is found. Then, the level is populated by random background textures (such as wall indents and vines), platforms, and enemies. In this step, pathway directions are also randomized. Finally the level is ready to play.






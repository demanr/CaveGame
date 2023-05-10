# The Cave Game - Caravan

This project is a dungeon exploration game made using procedural level generation. It procedurally generates room quantity, locations, connections, tile decorations, platorms, and enemies. It is made using the Godot game engine.

### Demo

In Caravan you collect berries all while trying to escape deeper into the caves by finding the exit door. But watch out! There are enemies in the cave that have corrosive slime. Good news- you are also a corrosive slime, but an extra cool version as you've figured out how to shoot slime as to clear the way for success. Defeat enemies, collect berries, and see how far you can travel!

https://user-images.githubusercontent.com/97637778/216750694-d3950c5c-aa46-4783-a978-ba9da43100f9.mov

### Generation

The generation is highly customizable. Room number, room size, and vertical or horizontal generation preference can be set before generation. Below is a video demo of the step by step process of generation. Firstly, a large amount of physics bodies are spawned in the exact same location, and as such collide with one another to create a random pattern. Then, some bodies are randomly removed, and the A* pathfinding algorithm is used to connect the rooms. This can be repeated many times until a suitable generation is found. Then, the level is populated by random background textures (such as wall indents and vines), platforms, and enemies. In this step, pathway directions are also randomized. Finally the level is ready to play.

https://user-images.githubusercontent.com/97637778/216751154-32e8c0d5-e0c6-45db-9c64-339ba41cb226.mov


### Extra Features

I wanted to really play with the whole idea of a translucent player. In the future I hope to add puzzles that can utilize this, which is why the character stops emitting light when unmoving, and how light can shine through the player (maybe it can relate to some story aspects someday as well if I choose to continue with this project!). Here is a demonstration of the AFK and lighting effect.

https://user-images.githubusercontent.com/97637778/216751276-53b6f9ea-6862-4129-939b-63f4100fd764.mov

## Art/Music

Despite not being an artist by any means, I am quite proud of how all the spritework turned out. It was a great learning opportunity to figure out how to make spritesheets, background, and animations that work cohesively together. I would have loved to have music and sound effects, but due to being the only person working on this project I had no real means of creating something that wouldn't redact from the game. Perhaps in the future I will add some small sound effects.

# Conclusion

Big thanks to the kidscancode blogs, as one really helped me understand how to go about room layout and path creation. The blog mentioned can be found here: http://kidscancode.org/blog/2018/12/godot3_procgen6/ 

Thank you for reading!

https://user-images.githubusercontent.com/97637778/216751438-b54361e8-0f07-497c-8f65-6b71fe98b084.mov



## A Lua Script That Spawns Several GTA V Objects Using YimMenu.

![object_spawner](https://github.com/xesdoog/object-spawner/assets/66764345/f55443fd-0ed5-41ca-9d75-1940192b8720)
![object_spawner(2)](https://github.com/xesdoog/object-spawner/assets/66764345/8c5910ea-b252-4951-a8b5-145617156107)

## Setup:
- Go to the [Releases](https://github.com/xesdoog/object-spawner/releases/latest) tab and download the latest version.
- Unzip the archive and place both **object_spawner.lua** and **proplist.lua** inside YimMenu's scripts folder which is located at:
  ######
      %AppData%\YimMenu\scripts

## Usage :
- By default, objects will spawn on the ground, facing the player. You can move them by enabling **Edit Mode**.
- To reposition the object, drag the corresponding **Axis slider** and hold it. Adjust the speed at which the object moves by dragging the slider while holding LMB down. The farther from the center, the faster the object moves in that direction.
- **Attaching Objects:** [WIP]
    - Spawn an object.
    - Activate the ![image](https://github.com/xesdoog/object-spawner/assets/66764345/8897ec31-b494-4c31-b7a7-499591fdc84b) checkbox.
    - Select a placement from the dropdown list that will apear after checking the box.
    - Press **Attach To Yourself**.
      > You can also attach objects to other players. First you need to select a player from YimMenu's player list then go back to the script and press **Attach To Player**. Keep in mind that this feature was never tested since I don't like toxic behavior but people asked for it so this will have bugs. Assuming it even works.
    - You can adjust the position of attached objects by enabling **Edit Mode** and using the sliders.
      > TIP: You can CTRL + left click on a slider to enter custom values.

## Issues :
* Some props can be used as _wrecking balls?_ I will probably have to force disable object collision in Edit Mode.

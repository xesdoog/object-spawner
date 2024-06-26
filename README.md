## A Lua Script That Spawns GTA V Objects Using YimMenu.

![object_spawner](https://github.com/xesdoog/object-spawner/assets/66764345/8d7e9b57-b57c-48bb-a1b6-aa99c86d2c88)

![object_spawner(2)](https://github.com/xesdoog/object-spawner/assets/66764345/8c5910ea-b252-4951-a8b5-145617156107)

## Setup:
- Go to the [Releases](https://github.com/xesdoog/object-spawner/releases/latest) tab and download the latest version.
- Unzip the archive and place **object_spawner.lua** and **os_data.lua** inside YimMenu's scripts folder which is located at:
  ######
      %AppData%\YimMenu\scripts

## Usage :
- By default, objects will spawn on the ground, facing the player. You can move them by enabling **Edit Mode**.
- To reposition an object, first select it from the dropdown list that will appear after you spawn it then drag the corresponding **Axis slider** and hold it. Adjust the speed at which the object moves by dragging the slider while holding LMB down. The farther from the center, the faster the object moves in that direction.

  > TIP: You can CTRL + left click on a slider to manually enter custom/more precise values.

- **Attaching Objects:**
    - Spawn an object.
    - Select it from the dropdown list.
    - Activate the ![image](https://github.com/xesdoog/object-spawner/assets/66764345/8897ec31-b494-4c31-b7a7-499591fdc84b) checkbox.
    - Select a placement from the dropdown list that will apear after checking the box.
    - Press **Attach To Yourself**.
    - You can adjust the position of attached objects by enabling **Edit Mode** and using the axis buttons. The initial axis values are very small, allowing precise movements. You can increase these values by increasing the multiplier.

## Issues :
* Some props can be used as _wrecking balls?_ I will probably have to force disable object collision when **Edit Mode** is active.

# Ram edit  

![Use landscape](Images/UseLandscape.gif)

Utility ROM to change the main memory of NES to any value and pass the value to other games.  

## Assemble  
Assemble using nesasm.  

```shell
nesasm Main.asm
```

[build.bat](build.bat) is available for windows.  

## Cartridge  
Burn to MMC3 cartridge with (512 bytes or more) SRAM.  

## How to  
### Memory editing  

| Key                   | Description                                           |
|:----------------------|:------------------------------------------------------|
| D-Pad                 | Move cursor                                           |
| A + D-Pad Up          | Decrement the value at the cursor position            |
| A + D-Pad Down        | Increment the value at the cursor position            |
| Select + D-Pad Left   | Move to previous page                                 |
| Select + D-Pad Right  | Move to next page                                     |
| A + Select            | Copy nibble at cursor position                        |
| B                     | Pastes the copied nibble at the cursor position       |
| Start                 | Open menu                                             |

### Menu  

| Key                   | Description                                           |
|:----------------------|:------------------------------------------------------|
| D-Pad Up              | Move cursor up                                        |
| D-Pad Down            | Move cursor down                                      |
| A                     | Confirm                                               |
| Start                 | Close menu                                            |
| B                     | Close menu                                            |

#### Fill all  
Fill all memory (2048 bytes) with the value at the cursor position.  

#### Fill page  
Fill page (64 bytes) with value at cursor position.  

#### User define  
Initialize to a pre-defined value.  
See also the `User define` section below.  

## User define  
It has 4 presets that can initialize memory to specific values.  
Create `UserDefine/blabla.asm` file and edit [UserDefine.asm](UserDefine.asm) file.  
Or edit the NES file directly. (Slot1:0x0010-0x080F, ..., Slot4:0x1810-0x200F)  
As a sample, memory definition is set in slot 1 to restart from World-T for SMB.  

## ToDo  
* None so far  

## Warning  
Removing and inserting the cassette while the power is on may damage the NES main unit.  
Use at your own risk.  

## License  
[MIT License](LICENSE).  

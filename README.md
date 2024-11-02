# Symlink Manager
![image](https://github.com/user-attachments/assets/56479f14-890e-4032-9d27-b74d3d4e915b)


By KnownGecko


## Introduction
Symlink manager allows you to declaratively manage your symlinks through a simple lua configuration file!

## Usage
To run the program, please run symlink-manager /the/directory/to/the/file/theconfigurationfile.lua. If no argument is provided, it will be assumed that there is a symlink.lua file in the directory you are running the program from.

```lua
local Configuration = {
    Symlinks = {
        -- Symlink File            Source File
        ["/home/user/folder1"] = "/home/user/folder2",
    },
```
The key is link file directory, so the link file will be created at /home/user/folder1 in this scenario. It will point to /home/user/folder2. Please note that this is inverse to how ln works, as since lua cannot have multiple of the same keys, inversing the regular order allows for 1 directory to have multiple link files pointing to it.
```lua
    Settings = {
        AddSymlinkConfirmation = false;
        AddPathConfirmation = true;
        RemovePathConfirmation = true;
        CachePath = "/home/user/.config/";
        SuperuserCommand = "sudo";

        RandomActivationMessage = true;
        Licensed = false;
    }
```
- AddSymlinkConfirmation: Will ask you to allow the creation of the symlink file at the specified directory (bool: true / false)
- AddPathConfirmation:  Will ask you to allow the creation of the path at the specified directory (bool: true / false)
- RemovePathConfirmation:  Will ask you to remove the creation of the path at the specified directory (bool: true / false)
- CachePath: To know where symlink-manager previously created symlinks, a cache file must be used, this specifies the directory. **Please change "user" to your user!** (string: eg. /home/knowngecko/.config/)
- SuperuserCommand: Prepends the command to the bash commands that the program runs (string: eg. "sudo", "doas")
- RandomActivationMessage: Enables or disables the random message upon running the program to purchase a license (bool: true / false)
- Licensed: Bool you set to mark the program as licensed, disables activation message if true (bool: true / false) - Same functionality-wise to RandomActivationMessage

```lua
}

return Configuration
```
Note that the table names cannot be changed, they must be named this way. This example file can be found in example.lua.

## Packages
AUR (Official)

##  Licensing
Symlink-Manager utilises a source-first license. If this software meets your needs, please purchase a license on [Ko-Fi](https://ko-fi.com/s/f7d3444a62) (Cost: £3).
Please note that there is no locked functionality behind the license, as mentioned above.


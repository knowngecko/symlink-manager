--<> Global Variables
local CacheFileName = "symlinks.cache";
if arg[1] ~= nil then package.path = package.path .. ";" .. arg[1] .. "/?.lua" end local Configuration = require("symlink");
if Configuration.Settings.SuperuserCommand ~= "" then Configuration.Settings.SuperuserCommand = Configuration.Settings.SuperuserCommand.. " "; end

local Colours = {
    Reset = "\27[0m",
    Red = "\27[31m",
    Green = "\27[32m",
    Yellow = "\27[33m",
    Blue = "\27[34m",
    Magenta = "\27[35m",
    Cyan = "\27[36m",
    White = "\27[37m",
}

--<> Activation Message
if Configuration.Settings.RandomActivationMessage == true and Configuration.Settings.Licensed == false then
    if math.random(0, 6) == 1 then -- 1 in 6 chance of showing
        print(Colours.Cyan .."[ACTIVATION] If you find this product useful, please purchase a license from: https://ko-fi.com/s/f7d3444a62, it really helps!".. Colours.Reset);
    end
end

--<> Functions
--> Internal errors that cause the program to exit, but not officially
local function fake_error(Message, ExitStatus)
    print(Colours.Red.. Message ..Colours.Reset);
    os.exit(ExitStatus);
end

--> Get Confirmation for any external action
local function ensure_confirmation()
    local Input = string.lower(io.read());
    if Input == "y" or Input == "yes" then
        return true;
    elseif Input == "n" or Input == "no" then
        return false;
    else
        print(Colours.Red.. "Unknown Input: ".. Input .." Assuming confirmation not granted!".. Colours.Reset);
    end
end

--> Expands variables from directory path, does not check validity
local function real_path(Path)
    --local Handle = io.popen("realpath ".. Path) -- Also evaluates symlinks, which is not behaviour we want
    local Handle = io.popen("echo ".. Path);
    local Read = Handle:read("*a");
    Handle:close();
    return string.sub(Read, 0, -2);
end

--> Removes the target path
local function remove_path(Location)
    if os.execute(Configuration.Settings.SuperuserCommand .."test -e " ..Location) then
        local Confirmation = true;
        if Configuration.Settings.RemovePathConfirmation == true then
            io.write(Colours.Yellow.. "[INPUT REQUIRED] Are you sure you would like to REMOVE the path: ".. Location.. " (y/n) ".. Colours.Reset);
            Confirmation = ensure_confirmation();
        end
        if Confirmation then
            print(Colours.Red.. "Removing path: ".. Location.. Colours.Reset);
            if os.execute(Configuration.Settings.SuperuserCommand.. "rm -r ".. Location) then
                return;
            end
        end
        fake_error("[EXIT] Unable to remove path: ".. Location, -2);
    end
end

--> Creates the target path
local function create_path(Location)
    local Confirmation = true;
    if Configuration.Settings.AddPathConfirmation == true then
        io.write(Colours.Yellow.. "[INPUT REQUIRED] Are you sure you would like to CREATE the path: ".. Location.. " (y/n)".. Colours.Reset);
        Confirmation = ensure_confirmation();
    end
    if Confirmation then
        print(Colours.Green.. "Creating path: ".. Location.. Colours.Reset);
        if os.execute(Configuration.Settings.SuperuserCommand.. "mkdir -p ".. Location) then 
            return;
        end
    end
    fake_error("[EXIT] Unable to create path at: ".. Location, -2);
end

--<> Manage Cache
Configuration.Settings.CachePath = real_path(Configuration.Settings.CachePath);
--> Ensure trailing slash
if string.sub(Configuration.Settings.CachePath, -1) ~= "/" then
    Configuration.Settings.CachePath = Configuration.Settings.CachePath.. "/";
end

--> Test if the path exists
local CacheDirectoryExists = os.execute(Configuration.Settings.SuperuserCommand .."test -d ".. Configuration.Settings.CachePath);
if CacheDirectoryExists == nil then
    print("Cache Directory doesn't exist, generating a new one at: ".. Configuration.Settings.CachePath ..CacheFileName);

    --> Create the directory if it doesn't exist
    create_path(Configuration.Settings.CachePath);
end

--> Test if the File exists
local CacheFileExists = os.execute(Configuration.Settings.SuperuserCommand .."test -f ".. Configuration.Settings.CachePath ..CacheFileName);
if CacheFileExists == nil then
    print("Cache File doesn't exist, generating a new one at: ".. Configuration.Settings.CachePath ..CacheFileName);

    --> Create the file if it doesn't exist
    if not os.execute(Configuration.Settings.SuperuserCommand.. "touch ".. Configuration.Settings.CachePath ..CacheFileName) then
        fake_error("[EXIT] Failed to create Cache File at: ".. Configuration.Settings.CachePath, -1);
    end
end

local Handle = io.popen(Configuration.Settings.SuperuserCommand .."cat ".. Configuration.Settings.CachePath ..CacheFileName);
local CacheFileContents = Handle:read(); Handle:close();

if CacheFileContents ~= nil then
    --> Split the string every 2 null bytes (as symlinks come in diretory pairs)
    local Splits = {};
    local PreviousSplit = 0;
    local Switch = false;

    for Index = 1, #CacheFileContents do
        local Character = CacheFileContents:sub(Index, Index);
        if Character == '\0' then
            --> Switch flips from true to false, to only get every other null byte.
            if Switch == true then
                table.insert(Splits, CacheFileContents:sub(PreviousSplit, Index-1));
                PreviousSplit = Index+1;
                Switch = false;
            else
                Switch = true;
            end
        end
    end

    --> Split each pair into its individual directory
    for Index, Value in pairs(Splits) do
        local NullPosition = Value:find("\0");
        local SegmentOne = Value:sub(1, NullPosition-1);
        local SegmentTwo = Value:sub(NullPosition+1, -1);
        --print("SegmentOne: ".. SegmentOne .." SegmentTwo: ".. SegmentTwo);

        --> Remove only if we no longer want the symlink
        if Configuration.Symlinks[SegmentOne] ~= nil then
            --> Expand variables
            SegmentOne = real_path(SegmentOne);
            SegmentTwo = real_path(SegmentTwo);
            --> Check if the path is a symlink
            if os.execute(Configuration.Settings.SuperuserCommand .."test -L " ..SegmentTwo) then
                --> Check if the symlink points to the intended source directory
                local Handle = io.popen(Configuration.Settings.SuperuserCommand .."readlink ".. SegmentTwo);
                if Handle:read() ~= SegmentOne then
                    remove_path(SegmentTwo);
                end 
                Handle:close();
            else
                remove_path(SegmentTwo);
            end
        else
            remove_path(SegmentTwo);
        end
    end
end

--<> Create Symlinks and update cache
--> SegmentOne is Source Dir, SegmentTwo is link dir
local NewCache = "";
for SegmentOne, SegmentTwo in pairs(Configuration.Symlinks) do
    --> Only create path if it doesn't exist
    if os.execute(Configuration.Settings.SuperuserCommand .."test -e ".. SegmentTwo) == nil then
        --> Ensure that source path exists
        if os.execute(Configuration.Settings.SuperuserCommand .."test -e ".. SegmentOne) == nil then
            fake_error("[EXIT] Source path does not exist: ".. SegmentOne, -1);
        end
        --> Create the symlink
        local Confirmation = true;
        if Configuration.Settings.AddSymlinkConfirmation then
            io.write(Colours.Yellow.. "[INPUT REQUIRED] Are you sure you would like a symlink from Source: ".. SegmentOne.. " Symlink File: ".. SegmentTwo .." (y/n)".. Colours.Reset);
            Confirmation = ensure_confirmation();
        end
        if Confirmation then
            os.execute(Configuration.Settings.SuperuserCommand .."ln -s ".. SegmentOne .. " ".. SegmentTwo);
            print(Colours.Green .."Created Symlink, Source: ".. SegmentOne .. ", Symlink File: ".. SegmentTwo ..Colours.Reset);
        end
    end

    --> Update string to write to cache file
    NewCache = NewCache.. SegmentOne.."\\0"..SegmentTwo.."\\0";
end

--> Write to cache file
os.execute(Configuration.Settings.SuperuserCommand .. " printf \"".. NewCache .."\" > " .. Configuration.Settings.CachePath .. CacheFileName);

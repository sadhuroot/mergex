```
                                                      $$\   $$\ 
                                                      $$ |  $$ |
$$$$$$\$$$$\   $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\  \$$\ $$  |
$$  _$$  _$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\  \$$$$  / 
$$ / $$ / $$ |$$$$$$$$ |$$ |  \__|$$ /  $$ |$$$$$$$$ | $$  $$<  
$$ | $$ | $$ |$$   ____|$$ |      $$ |  $$ |$$   ____|$$  /\$$\ 
$$ | $$ | $$ |\$$$$$$$\ $$ |      \$$$$$$$ |\$$$$$$$\ $$ /  $$ |
\__| \__| \__| \_______|\__|       \____$$ | \_______|\__|  \__|
                                  $$\   $$ |                    
                                  \$$$$$$  |                    
                                   \______/                     
```

Tool to find and merge all `.pcap` and `.pcapng` files on the system, remove duplicate WPA handshakes, and generate a clean `.22000` output — ready for use with tools like `hashcat`.
---

### MergeX – PCAP & Hash Merger Tool
```
git clone https://github.com/sadhuroot/mergex
```
```
cd mergex
````
```
chmod +x mergex.sh
```
```
./mergex -h
````

**Usage:**  
`./mergex.sh [source_path] [output_file]`

**Example:**  
`./mergex.sh ~/handshakes clearhashes.22000`

**Options:**
- `-h`   Show this help message  
- `-ai`  Auto-search and merge all PCAP files on the system

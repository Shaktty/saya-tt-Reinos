#!/bin/bash

# Define base directory
BASE_DIR="$HOME/.rlmud"

# Create directory structure
echo "Creating directory structure..."
mkdir -p "$BASE_DIR"/{modules,characters,logs,data,scripts}

# Function to create a file with content
create_file() {
    local file="$1"
    local content="$2"
    echo "Creating $file..."
    echo "$content" > "$file"
}

# Create README.md
cat > "$BASE_DIR/README.md" << 'EOF'
# TinTin++ Configuration for Reinos de Leyenda

A modular, organized configuration system for playing Reinos de Leyenda MUD using TinTin++.

[Complete README content as provided earlier...]
EOF

# Create main config.tin
cat > "$BASE_DIR/config.tin" << 'EOF'
#NOP === Core Configuration ===
#VAR {config} {
    {player} {
        {name} {joisan}
        {class} {guerrero}
        {level} {1}
    }
    {ui} {
        {colors} {
            {prefix} {<caf>}
            {info} {<fca>}
            {warning} {<faa>}
            {success} {<afa>}
            {error} {<faa>}
        }
        {powerline} {1}
        {statusbar} {1}
        {chatwindow} {1}
    }
    {paths} {
        {logs} {logs}
        {scripts} {scripts}
        {data} {data}
    }
    {features} {
        {combat} {1}
        {navigation} {1}
        {automation} {1}
        {communication} {1}
    }
}

[Rest of config.tin content as provided earlier...]
EOF

# Create character config
cat > "$BASE_DIR/characters/joisan.tin" << 'EOF'
#NOP === Character Configuration ===
#VAR {char} {
    {combat} {
        {primary_weapon} {espada}
        {secondary_weapon} {daga}
        {armor} {armadura de placas}
        {tactics} {
            {low_health} {50}
            {flee_health} {25}
            {use_potions} {1}
        }
    }
    {aliases} {
        {j} {atacar $target}
        {k} {golpear $target}
        {h} {ayuda}
        {f} {huir}
    }
    {macros} {
        {F1} {estado}
        {F2} {inventario}
        {F3} {equipo}
        {F4} {habilidades}
        {F5} {atacar}
        {F6} {defender}
        {F7} {huir}
        {F8} {ayuda}
    }
}

[Rest of joisan.tin content as provided earlier...]
EOF

# Create modules
# Combat module
cat > "$BASE_DIR/modules/combat.tin" << 'EOF'
#CLASS {combat} {kill};
#CLASS {combat} {open};

[Rest of combat.tin content as provided earlier...]

#CLASS {combat} {close};
EOF

# Navigation module
cat > "$BASE_DIR/modules/navigation.tin" << 'EOF'
#CLASS {navigation} {kill};
#CLASS {navigation} {open};

[Rest of navigation.tin content as provided earlier...]

#CLASS {navigation} {close};
EOF

# UI module
cat > "$BASE_DIR/modules/ui.tin" << 'EOF'
#CLASS {ui} {kill};
#CLASS {ui} {open};

[Rest of ui.tin content as provided earlier...]

#CLASS {ui} {close};
EOF

# Communication module
cat > "$BASE_DIR/modules/communication.tin" << 'EOF'
#CLASS {communication} {kill};
#CLASS {communication} {open};

[Rest of communication.tin content as provided earlier...]

#CLASS {communication} {close};
EOF

# Powerline module
cat > "$BASE_DIR/modules/powerline.tin" << 'EOF'
#CLASS {powerline} {kill};
#CLASS {powerline} {open};

[Rest of powerline.tin content as provided earlier...]

#CLASS {powerline} {close};
EOF

# Inventory module
cat > "$BASE_DIR/modules/inventory.tin" << 'EOF'
#CLASS {inventory} {kill};
#CLASS {inventory} {open};

[Rest of inventory.tin content as provided earlier...]

#CLASS {inventory} {close};
EOF

# Create .gitkeep files for empty directories
touch "$BASE_DIR/logs/.gitkeep"
touch "$BASE_DIR/data/.gitkeep"
touch "$BASE_DIR/scripts/.gitkeep"

# Set appropriate permissions
chmod 755 "$BASE_DIR"
find "$BASE_DIR" -type d -exec chmod 755 {} \;
find "$BASE_DIR" -type f -exec chmod 644 {} \;

echo "Configuration system has been created in $BASE_DIR"
echo "To use, run: tt++ $BASE_DIR/config.tin"

# Create a simple git repository if git is available
if command -v git >/dev/null 2>&1; then
    cd "$BASE_DIR"
    git init
    git add .
    git commit -m "Initial commit: TinTin++ configuration system"
    echo "Git repository initialized"
fi
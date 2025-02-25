#!/bin/bash

# Define base directory and create structure
BASE_DIR="$HOME/.rlmud"
mkdir -p "$BASE_DIR"/{modules,characters,logs,data,scripts}

# Create README.md
cat > "$BASE_DIR/README.md" << 'EOF'
# TinTin++ Configuration for Reinos de Leyenda

A modular, organized configuration system for playing Reinos de Leyenda MUD using TinTin++.

## Directory Structure
```
.
├── README.md
├── config.tin              # Main configuration file
├── characters/            # Character-specific configurations
│   └── joisan.tin
├── modules/              # Core functionality modules
│   ├── combat.tin
│   ├── communication.tin
│   ├── inventory.tin
│   ├── navigation.tin
│   ├── powerline.tin
│   └── ui.tin
├── logs/                 # Log files directory
├── data/                 # Character data storage
└── scripts/             # Additional scripts
```

## Quick Start
1. Run TinTin++ with: tt++ ~/.rlmud/config.tin
2. Character configuration is in characters/joisan.tin
3. Logs are stored in logs/
4. Custom scripts can be added to scripts/

## Commands
- Movement: n, s, e, o, ne, no, se, so
- Combat: j (attack), k (special attack)
- Stealth: sigilo, normal, combate
- Status: estado, eq

## Function Keys
F1: Status
F2: Inventory
F3: Equipment
F4: Skills
F5: Attack
F6: Defend
F7: Flee
F8: Help

## Support
Check logs directory for debugging information.
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

#NOP === Core Functions ===
#FUNCTION {load_module} {
    #IF {"%1" == ""} {
        #RETURN #ERROR No module specified;
    }
    #READ {modules/%1.tin};
    #RETURN #OK Module loaded: %1;
}

#NOP === Initialize Core Systems ===
#ALIAS {init_core} {
    #FOREACH {$config[paths][]} {path} {
        #SYSTEM {mkdir -p $path};
    }

    #NOP Load essential modules
    load_module combat;
    load_module navigation;
    load_module communication;
    load_module ui;
    load_module powerline;
    load_module inventory;

    #NOP Setup logging
    #FORMAT {log_file} {%s/%s_%t.log} {$config[paths][logs]} {$config[player][name]} {%Y-%m-%d};
    #LOG {APPEND} {$log_file};
}

#NOP === Main Initialization ===
init_core;

#NOP === Load Character Specific Config ===
#READ {characters/$config[player][name].tin};
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

#NOP === Character Specific Aliases ===
#FOREACH {$char[aliases][]} {alias} {name} {
    #ALIAS {$name} {$alias};
}

#NOP === Equipment Setup ===
#ALIAS {setup_equipment} {
    #SEND {equipar $char[combat][primary_weapon]};
    #SEND {equipar $char[combat][armor]};
}

#NOP === Character Specific Triggers ===
#ACTION {^Tu golpe causa %1 puntos de daño a %2.$} {
    #VAR {last_damage} {%1};
    #VAR {last_target} {%2};
    update_combat_status;
}

#ACTION {^Has sido herid{o|a} por %1.$} {
    check_health_status;
}

#NOP === Initialize Character ===
#ALIAS {init_char} {
    setup_equipment;
    #SHOWME {<128>Personaje inicializado: $config[player][name]<099>};
}

init_char;
EOF
# Create modules/combat.tin
cat > "$BASE_DIR/modules/combat.tin" << 'EOF'
#CLASS {combat} {kill};
#CLASS {combat} {open};

#NOP === Combat State Variables ===
#VAR {combat} {
    {active} {0}
    {target} {}
    {targets} {}
    {last_hit} {0}
    {combo} {0}
    {status} {
        {health} {100}
        {max_health} {100}
        {energy} {100}
        {max_energy} {100}
    }
    {buffs} {
        {images} {0}
        {shield} {0}
        {armor} {0}
    }
}

#NOP === Combat Functions ===
#FUNCTION {update_combat_status} {
    #MATH {combat[combo]} {$combat[combo] + 1};
    #FORMAT {combat[last_hit]} {%T};
    update_display;
}

#FUNCTION {reset_combat} {
    #VAR {combat[combo]} {0};
    #VAR {combat[target]} {};
    update_display;
}

#FUNCTION {check_health_status} {
    #IF {$combat[status][health] <= $char[tactics][flee_health]} {
        #SHOWME {<118>¡SALUD CRÍTICA! ¡HUYE!<099>};
        #IF {$char[tactics][use_potions]} {
            use_health_potion;
        };
    };
}

#NOP === Combat Actions ===
#ALIAS {atacar} {
    #IF {"%1" == ""} {
        #IF {"$combat[target]" == ""} {
            #ECHO {<138>Error: No target specified<099>};
            #RETURN;
        };
        #ELSE {
            #VAR {target} {$combat[target]};
        };
    };
    #ELSE {
        #VAR {combat[target]} {%1};
        #VAR {target} {%1};
    };

    #SEND {atacar $target};
    update_combat_status;
}

#ALIAS {golpear} {
    #IF {"$combat[target]" != ""} {
        #SEND {golpear $combat[target]};
        update_combat_status;
    };
}

#ALIAS {use_health_potion} {
    #IF {$char[tactics][use_potions]} {
        #SEND {beber pocion};
    };
}

#NOP === Combat Triggers ===
#ACTION {^%w cae al suelo sin vida.$} {
    #IF {"%1" == "$combat[target]"} {
        reset_combat;
    };
    #SHOWME {<128>¡Victoria! %1 ha caído<099>};
}

#ACTION {^Estás luchando contra %w.$} {
    #VAR {combat[target]} {%1};
    #VAR {combat[active]} {1};
    update_display;
}

#ACTION {^Ya no estás luchando.$} {
    reset_combat;
}

#ACTION {^%* te ha matado.$} {
    #VAR {combat[active]} {0};
    #SHOWME {<118>¡Has muerto!<099>};
}

#NOP === Status Monitoring ===
#ACTION {^Pvs: %d/%d  Pe: %d/%d} {
    #VAR {combat[status][health]} {%1};
    #VAR {combat[status][max_health]} {%2};
    #VAR {combat[status][energy]} {%3};
    #VAR {combat[status][max_energy]} {%4};
    update_display;
}

#CLASS {combat} {close};
EOF

# Create modules/navigation.tin
cat > "$BASE_DIR/modules/navigation.tin" << 'EOF'
#CLASS {navigation} {kill};
#CLASS {navigation} {open};

#NOP === Navigation State ===
#VAR {navigation} {
    {current_room} {}
    {last_room} {}
    {path} {}
    {mode} {normal}
    {auto_move} {0}
    {safe_spots} {}
}

#NOP === Direction Mappings ===
#VAR {directions} {
    {n} {norte}
    {s} {sur}
    {e} {este}
    {o} {oeste}
    {ne} {noreste}
    {no} {noroeste}
    {se} {sudeste}
    {so} {sudoeste}
    {ar} {arriba}
    {ab} {abajo}
    {en} {entrar}
    {sa} {salir}
}

#NOP === Movement Functions ===
#FUNCTION {move} {
    #IF {"$navigation[mode]" == "sigilo"} {
        #SEND {sigilar %1};
    };
    #ELSEIF {"$navigation[mode]" == "combat"} {
        #SEND {galopar %1};
    };
    #ELSE {
        #SEND {%1};
    };
}

#FUNCTION {reverse_direction} {
    #SWITCH {"%1"} {
        #CASE {"n"} {#RETURN {s}};
        #CASE {"s"} {#RETURN {n}};
        #CASE {"e"} {#RETURN {o}};
        #CASE {"o"} {#RETURN {e}};
        #CASE {"ne"} {#RETURN {so}};
        #CASE {"no"} {#RETURN {se}};
        #CASE {"se"} {#RETURN {no}};
        #CASE {"so"} {#RETURN {ne}};
        #CASE {"ar"} {#RETURN {ab}};
        #CASE {"ab"} {#RETURN {ar}};
        #DEFAULT {#RETURN {%1}};
    };
}

#NOP === Navigation Aliases ===
#FOREACH {$directions[]} {short} {long} {
    #ALIAS {$short} {
        move $long;
    };
}

#ALIAS {sigilo} {
    #VAR {navigation[mode]} {sigilo};
    #SHOWME {<128>Modo sigilo activado<099>};
}

#ALIAS {normal} {
    #VAR {navigation[mode]} {normal};
    #SHOWME {<128>Modo normal activado<099>};
}

#ALIAS {combate} {
    #VAR {navigation[mode]} {combat};
    #SHOWME {<128>Modo combate activado<099>};
}

#ALIAS {recordar_sitio} {
    #VAR {navigation[safe_spots][%1]} {$navigation[current_room]};
    #SHOWME {<128>Sitio recordado: %1<099>};
}

#NOP === Auto-Movement ===
#ALIAS {/r} {
    #IF {"%1" == ""} {
        #SHOWME {<138>Uso: /r <dirección><099>};
        #RETURN;
    };

    #VAR {navigation[auto_move]} {1};
    #VAR {navigation[direction]} {%1};
    move %1;
}

#ACTION {^No puedes ir en esa dirección.$} {
    #IF {$navigation[auto_move]} {
        #VAR {navigation[auto_move]} {0};
        #SHOWME {<138>Auto-movimiento detenido: camino bloqueado<099>};
    };
}

#ACTION {^[%*]$} {
    #VAR {navigation[current_room]} {%1};
}

#CLASS {navigation} {close};
EOF

# Create modules/ui.tin
cat > "$BASE_DIR/modules/ui.tin" << 'EOF'
#CLASS {ui} {kill};
#CLASS {ui} {open};

#NOP === UI Configuration ===
#VAR {ui} {
    {colors} {
        {border} {<138>}
        {title} {<128>}
        {text} {<148>}
        {highlight} {<118>}
        {warning} {<138>}
        {error} {<118>}
    }
    {symbols} {
        {health} {♥}
        {energy} {⚡}
        {separator} {│}
        {corner} {+}
        {horizontal} {─}
        {vertical} {│}
    }
    {layout} {
        {main_height} {0}
        {chat_height} {5}
        {status_height} {2}
    }
}

#NOP === UI Functions ===
#FUNCTION {create_status_line} {
    #FORMAT {health_bar} {%s%d/%d%s} {$ui[colors][text]} {$combat[status][health]} {$combat[status][max_health]} {$ui[symbols][health]};
    #FORMAT {energy_bar} {%s%d/%d%s} {$ui[colors][text]} {$combat[status][energy]} {$combat[status][max_energy]} {$ui[symbols][energy]};
    #FORMAT {target_info} {%s%s} {$ui[colors][highlight]} {$combat[target]};

    #FORMAT {result} {%s %s %s %s %s %s}
        {$health_bar}
        {$ui[symbols][separator]}
        {$energy_bar}
        {$ui[symbols][separator]}
        {$target_info}
        {<099>};
}

#FUNCTION {update_display} {
    #SCREEN {get} {cols} {width};
    #FORMAT {status_line} {%s} {@create_status_line{}};
    #SHOWME {$status_line} {-1};
}

#FUNCTION {create_border} {
    #FORMAT {result} {%s%s%s}
        {$ui[colors][border]}
        {$ui[symbols][horizontal]}
        {<099>};
}

#NOP === Window Management ===
#EVENT {SCREEN RESIZE} {
    update_display;
}

#NOP === Chat Window ===
#IF {$config[ui][chatwindow]} {
    #SPLIT {$ui[layout][chat_height]};
}

#NOP === Message Formatting ===
#FUNCTION {format_message} {
    #FORMAT {result} {%s%s<099>} {$ui[colors][text]} {%1};
}

#ALIAS {msg} {
    #SHOWME {@format_message{%0}};
}

#CLASS {ui} {close};
EOF
# Create modules/communication.tin
cat > "$BASE_DIR/modules/communication.tin" << 'EOF'
#CLASS {communication} {kill};
#CLASS {communication} {open};

#NOP === Communication State ===
#VAR {communication} {
    {channels} {
        {chat} {1}
        {grupo} {1}
        {decir} {1}
        {gritar} {1}
    }
    {last_tell} {}
    {chat_history} {}
    {log_enabled} {1}
    {filters} {
        {spam} {1}
        {system} {1}
    }
}

#NOP === GMCP Communication Handling ===
#EVENT {IAC SB GMCP Comm.Channel.Text IAC SE} {
    #IF {$communication[log_enabled]} {
        #FORMAT {timestamp} {%t} {[%H:%M:%S]};
        #FORMAT {chat_line} {%s %s} {$timestamp} {%1};
        #SYSTEM {echo "$chat_line" >> logs/chat.log};
    };

    #IF {$config[ui][chatwindow]} {
        #SHOWME {%1} {-2};
    };
}

#NOP === Channel Management ===
#ALIAS {/chat} {
    #IF {"%1" == "on"} {
        #VAR {communication[channels][chat]} {1};
        #SHOWME {<128>Canal Chat activado<099>};
    };
    #ELSEIF {"%1" == "off"} {
        #VAR {communication[channels][chat]} {0};
        #SHOWME {<128>Canal Chat desactivado<099>};
    };
}

#ALIAS {/log} {
    #IF {"%1" == "on"} {
        #VAR {communication[log_enabled]} {1};
        #FORMAT {log_file} {logs/chat_%t.log} {%Y%m%d};
        #LOG {APPEND} {$log_file};
        #SHOWME {<128>Registro de chat activado: $log_file<099>};
    };
    #ELSEIF {"%1" == "off"} {
        #VAR {communication[log_enabled]} {0};
        #LOG {OFF};
        #SHOWME {<128>Registro de chat desactivado<099>};
    };
}

#ALIAS {/tell} {
    #IF {"%1" == ""} {
        #IF {"$communication[last_tell]" != ""} {
            #SEND {decir $communication[last_tell] %2};
        };
    };
    #ELSE {
        #VAR {communication[last_tell]} {%1};
        #SEND {decir %1 %2};
    };
}

#NOP === Chat Formatting ===
#SUBSTITUTE {^[Chat] %*} {<138>[Chat] %1<099>};
#SUBSTITUTE {^[Grupo] %*} {<128>[Grupo] %1<099>};
#SUBSTITUTE {^%w te dice '%*'} {<148>%1 te dice '%2'<099>};

#NOP === Chat History ===
#ACTION {^[%w] %*} {
    #LIST {communication[chat_history]} {ADD} {[%1] %2};
    #IF {$config[ui][chatwindow]} {
        #SHOWME {<138>[%1] <148>%2<099>} {-2};
    };
}

#ALIAS {/history} {
    #IF {"%1" == ""} {
        #VAR {lines} {10};
    };
    #ELSE {
        #VAR {lines} {%1};
    };

    #LIST {communication[chat_history]} {SIZE} {history_size};
    #MATH {start} {$history_size - $lines};
    #IF {$start < 0} {
        #VAR {start} {0};
    };

    #LOOP {$start} {$history_size} {count} {
        #SHOWME {$communication[chat_history][$count]};
    };
}

#CLASS {communication} {close};
EOF

# Create modules/powerline.tin
cat > "$BASE_DIR/modules/powerline.tin" << 'EOF'
#CLASS {powerline} {kill};
#CLASS {powerline} {open};

#VAR {powerline} {
    {enabled} {1}
    {style} {
        {separator} {⮀}
        {subseparator} {⮁}
        {space} { }
    }
    {segments} {
        {health} {1}
        {energy} {1}
        {target} {1}
        {buffs} {1}
        {position} {1}
    }
    {colors} {
        {health_high} {<128>}
        {health_med} {<138>}
        {health_low} {<118>}
        {energy} {<148>}
        {target} {<158>}
        {buffs} {<168>}
        {position} {<178>}
    }
}

#FUNCTION {get_health_color} {
    #MATH {health_percent} {%1 * 100 / %2};
    #IF {$health_percent > 75} {
        #RETURN {$powerline[colors][health_high]};
    };
    #ELSEIF {$health_percent > 25} {
        #RETURN {$powerline[colors][health_med]};
    };
    #ELSE {
        #RETURN {$powerline[colors][health_low]};
    };
}

#FUNCTION {create_powerline} {
    #VAR {line} {};

    #IF {$powerline[segments][health]} {
        #FORMAT {health_segment} {%s HP:%d/%d%s}
            {@get_health_color{$combat[status][health];$combat[status][max_health]}}
            {$combat[status][health]}
            {$combat[status][max_health]}
            {$powerline[style][separator]};
        #VAR {line} {$line$health_segment};
    };

    #IF {$powerline[segments][energy]} {
        #FORMAT {energy_segment} {%sEP:%d/%d%s}
            {$powerline[colors][energy]}
            {$combat[status][energy]}
            {$combat[status][max_energy]}
            {$powerline[style][separator]};
        #VAR {line} {$line$energy_segment};
    };

    #IF {$powerline[segments][target]} {
        #IF {"$combat[target]" != ""} {
            #FORMAT {target_segment} {%sTarget:%s%s}
                {$powerline[colors][target]}
                {$combat[target]}
                {$powerline[style][separator]};
            #VAR {line} {$line$target_segment};
        };
    };

    #IF {$powerline[segments][buffs]} {
        #IF {$combat[buffs][images] > 0} {
            #FORMAT {buffs_segment} {%sIMG:%d%s}
                {$powerline[colors][buffs]}
                {$combat[buffs][images]}
                {$powerline[style][subseparator]};
            #VAR {line} {$line$buffs_segment};
        };
    };

    #IF {$powerline[segments][position]} {
        #IF {"$navigation[current_room]" != ""} {
            #FORMAT {position_segment} {%s[%s]%s}
                {$powerline[colors][position]}
                {$navigation[current_room]}
                {$powerline[style][separator]};
            #VAR {line} {$line$position_segment};
        };
    };

    #RETURN {$line<099>};
}

#FUNCTION {update_powerline} {
    #IF {$powerline[enabled]} {
        #SHOWME {@create_powerline{}} {1};
    };
}

#EVENT {SCREEN RESIZE} {
    update_powerline;
}

#CLASS {powerline} {close};
EOF

# Create modules/inventory.tin
cat > "$BASE_DIR/modules/inventory.tin" << 'EOF'
#CLASS {inventory} {kill};
#CLASS {inventory} {open};

#VAR {inventory} {
    {equipment} {
        {head} {}
        {neck} {}
        {body} {}
        {arms} {}
        {hands} {}
        {finger1} {}
        {finger2} {}
        {waist} {}
        {legs} {}
        {feet} {}
        {weapon1} {}
        {weapon2} {}
    }
    {containers} {
        {mochila} {}
        {bolsa} {}
    }
    {weight} {0}
    {max_weight} {0}
    {valuable_items} {}
    {equipment_stats} {}
}

#NOP === Inventory Functions ===
#FUNCTION {parse_equipment_line} {
    #REGEX {%1} {{.*}: {.*}} {
        #VAR {slot} {&1};
        #VAR {item} {&2};
        #VAR {inventory[equipment][$slot]} {$item};
    };
}

#FUNCTION {calculate_total_weight} {
    #VAR {total} {0};
    #FOREACH {$inventory[containers][]} {container} {items} {
        #FOREACH {$items[]} {item} {weight} {
            #MATH {total} {$total + $weight};
        };
    };
    #VAR {inventory[weight]} {$total};
    #RETURN {$total};
}

#NOP === Inventory Actions ===
#ALIAS {/eq} {
    #FOREACH {$inventory[equipment][]} {slot} {item} {
        #IF {"$item" != ""} {
            #SHOWME {<138>$slot:<128> $item<099>};
        };
    };
}

#ALIAS {/peso} {
    #VAR {total} {@calculate_total_weight{}};
    #SHOWME {<138>Peso total:<128> $total/$inventory[max_weight]<099>};
}

#ALIAS {equipar} {
    #IF {"%1" == ""} {
        #SHOWME {<138>Uso: equipar <objeto><099>};
        #RETURN;
    };
    #SEND {equipar %1};
}

#ALIAS {desequipar} {
    #IF {"%1" == ""} {
        #SHOWME {<138>Uso: desequipar <objeto><099>};
        #RETURN;
    };
    #SEND {desequipar %1};
}

#NOP === Inventory Triggers ===
#ACTION {^Llevas equipado:$} {
    #ACTION {^%*: %*$} {
        parse_equipment_line {%%1: %%2};
    } {5};
}

#ACTION {^Acabas de equiparte %* en %*.$} {
    #VAR {inventory[equipment][%2]} {%1};
    update_display;
}

#ACTION {^Te quitas %* de %*.$} {
    #VAR {inventory[equipment][%2]} {};
    update_display;
}

#ACTION {^Tu mochila contiene:$} {
    #VAR {inventory[containers][mochila]} {};
}

#ACTION {^%d) %w %*} {
    #VAR {inventory[containers][mochila][%2]} {
        {quantity} {%1}
        {description} {%3}
    };
}

#NOP === Value Tracking ===
#ACTION {^%w vale %d monedas de %w.$} {
    #VAR {inventory[valuable_items][%1]} {
        {value} {%2}
        {type} {%3}
    };
}

#CLASS {inventory} {close};
EOF

# Set appropriate permissions
chmod 755 "$BASE_DIR"
find "$BASE_DIR" -type d -exec chmod 755 {} \;
find "$BASE_DIR" -type f -exec chmod 644 {} \;

echo "Configuration system has been created in $BASE_DIR"
echo "Creating log directories and initial files..."

# Create necessary log directories and files
mkdir -p "$BASE_DIR/logs"
touch "$BASE_DIR/logs/.gitkeep"
mkdir -p "$BASE_DIR/data"
touch "$BASE_DIR/data/.gitkeep"

# Initialize git repository if git is available
if command -v git >/dev/null 2>&1; then
    cd "$BASE_DIR"
    git init
    git add .
    git commit -m "Initial commit: Complete TinTin++ configuration system"
    echo "Git repository initialized"
fi

echo "Installation complete!"
echo "To use the configuration, run: tt++ $BASE_DIR/config.tin"

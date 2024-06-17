**Popis kódu**
Tento skript pro Godot Engine generuje cesty v gridu pomocí uzlu Node2D. Hlavní části kódu zahrnují:

**Inicializace a spuštění generátoru:**

-Při spuštění scény se inicializuje generátor a spustí se funkce generate_loop_path, která generuje smyčku cesty v gridu.

**Generování smyčky cesty:**

-Kód inicializuje grid a nastaví startovní pozici cesty, která je více uprostřed gridu.
-Náhodně vybírá směry pro rozšíření cesty pomocí funkce get_valid_directions a kontroluje, zda rozšíření nezablokuje smyčku (will_block_loop).
Pokud je cesta dostatečně dlouhá nebo blízko startovní pozice, pokusí se připojit zpět k táboráku (connect_to_campfire).

**Odstraňování slepých cest:**

-Po dokončení generování cesty se zajišťuje, aby nezůstaly žádné slepé cesty pomocí funkce remove_dead_ends, která odstraňuje cesty s pouze jedním sousedním uzlem.
**Hlavní funkce**
_ready()

-Inicializuje generátor a spustí generování smyčky cesty.
generate_loop_path()

-Generuje smyčku cesty v gridu, náhodně vybírá směry a kontroluje, zda nedochází k zablokování smyčky.
get_valid_directions(grid, x, y)

-Vrací platné směry pro rozšíření cesty z dané pozice v gridu.
is_within_bounds(x, y)

-Kontroluje, zda jsou souřadnice uvnitř hranic gridu.
connect_to_campfire(grid, tilemap, x, y, start_x, start_y)

-Pokouší se připojit cestu zpět k táboráku.
will_block_loop(grid, x, y)

-Kontroluje, zda přidání cesty zablokuje smyčku.
remove_dead_ends(grid)

Odstraňuje slepé cesty z gridu.
count_adjacent_paths(grid, x, y)

Počítá sousední cesty kolem dané pozice v gridu.

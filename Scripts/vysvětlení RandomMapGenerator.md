### Celý skript `RandomMapGenerator.gd` s vysvětlením

```gdscript
extends Node3D

@export var tile_scene: PackedScene
```
**`@export var tile_scene: PackedScene`**
- **Co to znamená:** Exportovaná proměnná `tile_scene` typu `PackedScene`. To umožňuje nastavit tuto proměnnou přímo v editoru Godot. `PackedScene` je třída, která umožňuje instancovat scény za běhu.
- **Účel:** Uchovává referenci na scénu dlaždice, kterou budeme instancovat při generování cesty.

```gdscript
var path_points = []
var tile_size = Vector3(4, 0, 4)  # Velikost dlaždice
var grid = {}
var directions = [
    Vector3(tile_size.x, 0, 0),  # Right
    Vector3(-tile_size.x, 0, 0),  # Left
    Vector3(0, 0, tile_size.z),  # Forward
    Vector3(0, 0, -tile_size.z)  # Backward
]
var area_size = 50  # Velikost oblasti 50x50 metrů
```
**`var path_points = []`**
- **Co to znamená:** Proměnná `path_points` je prázdný seznam.
- **Účel:** Uchovává body cesty (pozice jednotlivých dlaždic), které tvoří generovanou cestu.

**`var tile_size = Vector3(4, 0, 4)`**
- **Co to znamená:** Proměnná `tile_size` je vektor o třech složkách, reprezentující velikost dlaždice.
- **Účel:** Definuje velikost jednotlivých dlaždic cesty.

**`var grid = {}`**
- **Co to znamená:** Proměnná `grid` je prázdný slovník.
- **Účel:** Uchovává informace o obsazených pozicích v mřížce, aby se zabránilo překrývání dlaždic.

**`var directions = [...]`**
- **Co to znamená:** Proměnná `directions` je seznam čtyř vektorů.
- **Účel:** Definuje možné směry, kterými se může cesta rozvětvit (vpravo, vlevo, vpřed, vzad).

**`var area_size = 50`**
- **Co to znamená:** Proměnná `area_size` je celé číslo.
- **Účel:** Definuje velikost oblasti, ve které se bude cesta generovat (50x50 metrů).

```gdscript
func _ready():
    print("Starting to generate path")
    var success = generate_closed_loop(Vector3(0, 0, 0))
    if success:
        create_path_tiles()
    else:
        print("Failed to generate a path")
```
**`func _ready()`**
- **Co to znamená:** Funkce `_ready` je vestavěná funkce Godot, která se volá, když je uzel připraven.
- **Účel:** Inicializuje proces generování cesty, když je uzel připraven.

**`print("Starting to generate path")`**
- **Co to znamená:** Tiskne zprávu do konzole.
- **Účel:** Informuje, že proces generování cesty začíná.

**`var success = generate_closed_loop(Vector3(0, 0, 0))`**
- **Co to znamená:** Volá funkci `generate_closed_loop` s počátečním bodem `(0, 0, 0)` a ukládá návratovou hodnotu do `success`.
- **Účel:** Pokouší se vygenerovat uzavřenou smyčku cesty.

**`if success: create_path_tiles() else: print("Failed to generate a path")`**
- **Co to znamená:** Kontroluje, zda byla cesta úspěšně vygenerována. Pokud ano, volá `create_path_tiles`, pokud ne, tiskne zprávu o selhání.
- **Účel:** Vytvoří dlaždice cesty, pokud byla cesta úspěšně vygenerována.

```gdscript
func generate_closed_loop(start: Vector3) -> bool:
    print("Generating closed loop")
    path_points.clear()
    grid.clear()
    path_points.append(start)
    grid[vec_to_key(start)] = true
```
**`func generate_closed_loop(start: Vector3) -> bool`**
- **Co to znamená:** Definuje funkci `generate_closed_loop`, která přijímá vektor `start` a vrací boolean (pravda/nepravda).
- **Účel:** Generuje uzavřenou smyčku cesty začínající od `start`.

**`path_points.clear()`**
- **Co to znamená:** Vymaže seznam `path_points`.
- **Účel:** Resetuje body cesty.

**`grid.clear()`**
- **Co to znamená:** Vymaže slovník `grid`.
- **Účel:** Resetuje obsazené pozice v mřížce.

**`path_points.append(start)`**
- **Co to znamená:** Přidá `start` do seznamu `path_points`.
- **Účel:** Nastaví počáteční bod cesty.

**`grid[vec_to_key(start)] = true`**
- **Co to znamená:** Přidá počáteční bod do `grid` jako obsazenou pozici.
- **Účel:** Označí počáteční bod jako obsazený v mřížce.

```gdscript
    var current_position = start
    var steps = 0
    while steps < 1000:
        var next_position = get_next_position(current_position)
        var attempts = 0
        while (grid.has(vec_to_key(next_position)) or count_neighbors(next_position) > 1 or not within_bounds(next_position)) and attempts < 100:
            next_position = get_next_position(current_position)
            attempts += 1

        if attempts >= 100:
            print("Failed to find a valid next position after 100 attempts at step", steps)
            return false

        path_points.append(next_position)
        grid[vec_to_key(next_position)] = true
        current_position = next_position
        steps += 1
        print("Step", steps, ": Moved to", next_position)

        if steps > 10 and randi() % 10 < 2:
            if is_path_closed(start):
                print("Closed loop generated successfully after", steps, "steps")
                return true

    return is_path_closed(start)
```
**`var current_position = start`**
- **Co to znamená:** Nastaví `current_position` na `start`.
- **Účel:** Inicializuje aktuální pozici na počáteční bod.

**`var steps = 0`**
- **Co to znamená:** Nastaví `steps` na 0.
- **Účel:** Inicializuje počet kroků.

**`while steps < 1000:`**
- **Co to znamená:** Spustí cyklus, dokud je `steps` menší než 1000.
- **Účel:** Omezuje počet kroků, aby se zabránilo nekonečné smyčce.

**`var next_position = get_next_position(current_position)`**
- **Co to znamená:** Zavolá funkci `get_next_position` s aktuální pozicí a uloží výsledek do `next_position`.
- **Účel:** Určuje další pozici pro dlaždici cesty.

**`var attempts = 0`**
- **Co to znamená:** Nastaví `attempts` na 0.
- **Účel:** Inicializuje počet pokusů.

**`while (grid.has(vec_to_key(next_position)) or count_neighbors(next_position) > 1 or not within_bounds(next_position)) and attempts < 100:`**
- **Co to znamená:** Spustí cyklus, dokud `next_position` není obsazená nebo má více než jednoho souseda nebo není v rámci oblasti a počet pokusů je menší než 100.
- **Účel:** Hledá platnou další pozici pro dlaždici cesty.

**`next_position = get_next_position(current_position)`**
- **Co to znamená:** Zavolá funkci `get_next_position` s aktuální pozicí a uloží výsledek do `next_position`.
- **Účel:** Určuje novou další pozici pro dlaždici cesty.

**`attempts += 1`**
- **Co to znamená:** Zvýší počet pokusů o 1.
- **Účel:** Sleduje počet pokusů o nalezení platné další pozice.

**`if attempts >= 100:`**
- **Co to znamená:** Kontroluje, zda počet pokusů dosáhl 100.
- **Účel:** Pokud se nepodařilo najít platnou další pozici po 100 pokusech, ukončí generování.

**`return false`**
- **Co to znamená:** Vrátí hodnotu `false

`.
- **Účel:** Označuje, že se nepodařilo vygenerovat cestu.

**`path_points.append(next_position)`**
- **Co to znamená:** Přidá `next_position` do seznamu `path_points`.
- **Účel:** Přidá další bod cesty.

**`grid[vec_to_key(next_position)] = true`**
- **Co to znamená:** Přidá `next_position` do `grid` jako obsazenou pozici.
- **Účel:** Označí další pozici jako obsazenou v mřížce.

**`current_position = next_position`**
- **Co to znamená:** Nastaví `current_position` na `next_position`.
- **Účel:** Aktualizuje aktuální pozici na další bod cesty.

**`steps += 1`**
- **Co to znamená:** Zvýší počet kroků o 1.
- **Účel:** Sleduje počet kroků při generování cesty.

**`print("Step", steps, ": Moved to", next_position)`**
- **Co to znamená:** Tiskne zprávu do konzole.
- **Účel:** Informuje o aktuálním kroku a pozici.

**`if steps > 10 and randi() % 10 < 2:`**
- **Co to znamená:** Kontroluje, zda je počet kroků větší než 10 a zda náhodné číslo je menší než 2.
- **Účel:** S 20% pravděpodobností se pokusí uzavřít smyčku po více než 10 krocích.

**`if is_path_closed(start):`**
- **Co to znamená:** Kontroluje, zda je cesta uzavřená.
- **Účel:** Pokud je cesta uzavřená, vrátí hodnotu `true`.

**`return is_path_closed(start)`**
- **Co to znamená:** Vrátí výsledek funkce `is_path_closed`.
- **Účel:** Po dosažení maximálního počtu kroků se pokusí uzavřít smyčku.

```gdscript
func get_next_position(current_position: Vector3) -> Vector3:
    var valid_directions = []
    for direction in directions:
        var next_position = current_position + direction
        if not grid.has(vec_to_key(next_position)) and count_neighbors(next_position) == 1 and within_bounds(next_position):
            valid_directions.append(direction)
    
    if valid_directions.size() == 0:
        return current_position + directions[randi() % directions.size()]

    return current_position + valid_directions[randi() % valid_directions.size()]
```
**`func get_next_position(current_position: Vector3) -> Vector3`**
- **Co to znamená:** Definuje funkci `get_next_position`, která přijímá vektor `current_position` a vrací vektor.
- **Účel:** Určuje další platnou pozici pro dlaždici cesty.

**`var valid_directions = []`**
- **Co to znamená:** Nastaví `valid_directions` na prázdný seznam.
- **Účel:** Uchovává platné směry, kterými se cesta může rozvětvit.

**`for direction in directions:`**
- **Co to znamená:** Prochází každý směr v seznamu `directions`.
- **Účel:** Prohledává možné směry pro další dlaždici cesty.

**`var next_position = current_position + direction`**
- **Co to znamená:** Nastaví `next_position` na součet `current_position` a `direction`.
- **Účel:** Určuje potenciální další pozici pro dlaždici cesty.

**`if not grid.has(vec_to_key(next_position)) and count_neighbors(next_position) == 1 and within_bounds(next_position):`**
- **Co to znamená:** Kontroluje, zda `next_position` není obsazená, má jednoho souseda a je v rámci oblasti.
- **Účel:** Určuje, zda je `next_position` platná pozice pro další dlaždici cesty.

**`valid_directions.append(direction)`**
- **Co to znamená:** Přidá `direction` do seznamu `valid_directions`.
- **Účel:** Uchovává platný směr pro další dlaždici cesty.

**`if valid_directions.size() == 0:`**
- **Co to znamená:** Kontroluje, zda je seznam `valid_directions` prázdný.
- **Účel:** Pokud neexistují žádné platné směry, vrátí náhodný směr.

**`return current_position + directions[randi() % directions.size()]`**
- **Co to znamená:** Vrátí aktuální pozici plus náhodný směr.
- **Účel:** Určuje další pozici náhodně, pokud neexistují žádné platné směry.

**`return current_position + valid_directions[randi() % valid_directions.size()]`**
- **Co to znamená:** Vrátí aktuální pozici plus náhodný platný směr.
- **Účel:** Určuje další pozici náhodně z platných směrů.

```gdscript
func within_bounds(position: Vector3) -> bool:
    return abs(position.x) <= area_size / 2 and abs(position.z) <= area_size / 2
```
**`func within_bounds(position: Vector3) -> bool`**
- **Co to znamená:** Definuje funkci `within_bounds`, která přijímá vektor `position` a vrací boolean.
- **Účel:** Kontroluje, zda je `position` v rámci oblasti 50x50 metrů.

**`return abs(position.x) <= area_size / 2 and abs(position.z) <= area_size / 2`**
- **Co to znamená:** Vrátí hodnotu `true`, pokud jsou absolutní hodnoty souřadnic x a z menší nebo rovné polovině `area_size`.
- **Účel:** Určuje, zda je `position` v rámci oblasti 50x50 metrů.

```gdscript
func vec_to_key(vec: Vector3) -> String:
    return str(vec.x) + "_" + str(vec.y) + "_" + str(vec.z)
```
**`func vec_to_key(vec: Vector3) -> String`**
- **Co to znamená:** Definuje funkci `vec_to_key`, která přijímá vektor `vec` a vrací řetězec.
- **Účel:** Převádí vektor na řetězec klíč pro použití ve slovníku.

**`return str(vec.x) + "_" + str(vec.y) + "_" + str(vec.z)`**
- **Co to znamená:** Vrátí řetězec složený z x, y a z složek vektoru, oddělených podtržítky.
- **Účel:** Vytváří jedinečný klíč pro každou pozici v mřížce.

```gdscript
func count_neighbors(pos: Vector3) -> int:
    var count = 0
    for direction in directions:
        if grid.has(vec_to_key(pos + direction)):
            count += 1
    return count
```
**`func count_neighbors(pos: Vector3) -> int`**
- **Co to znamená:** Definuje funkci `count_neighbors`, která přijímá vektor `pos` a vrací celé číslo.
- **Účel:** Počítá počet sousedních dlaždic pro danou pozici.

**`var count = 0`**
- **Co to znamená:** Nastaví `count` na 0.
- **Účel:** Inicializuje počet sousedů.

**`for direction in directions:`**
- **Co to znamená:** Prochází každý směr v seznamu `directions`.
- **Účel:** Prohledává možné směry pro sousední dlaždice.

**`if grid.has(vec_to_key(pos + direction)):`**
- **Co to znamená:** Kontroluje, zda je pozice sousední dlaždice obsazená.
- **Účel:** Určuje, zda je pozice sousední dlaždice obsazená.

**`count += 1`**
- **Co to znamená:** Zvýší počet sousedů o 1.
- **Účel:** Sleduje počet obsazených sousedních dlaždic.

**`return count`**
- **Co to znamená:** Vrátí počet sousedů.
- **Účel:** Určuje počet obsazených sousedních dlaždic pro danou pozici.

```gdscript
func is_path_closed(start: Vector3) -> bool:
    return path_points.size() > 1 and path_points[path_points.size() - 1].distance_to(start) <= tile_size.length() and count_neighbors(start) == 2
```
**`func is_path_closed(start: Vector3) -> bool`**
- **Co to znamená:** Definuje funkci `is_path_closed`, která přijímá vektor `start` a vrací boolean.
- **Účel:** Kontroluje, zda je cesta uzavřená.

**`return path_points.size() > 1 and path_points[path_points.size() - 

1].distance_to(start) <= tile_size.length() and count_neighbors(start) == 2`**
- **Co to znamená:** Vrátí hodnotu `true`, pokud je počet bodů cesty větší než 1, poslední bod cesty je blízko startu a start má dva sousedy.
- **Účel:** Určuje, zda je cesta uzavřená.

```gdscript
func create_path_tiles():
    if path_points.size() == 0:
        print("No path points to create tiles")
        return

    for i in range(path_points.size() - 1):
        var start_point = path_points[i]
        var end_point = path_points[i + 1]
        print("Creating path segment from ", start_point, " to ", end_point)
        create_path_segment(start_point, end_point)
```
**`func create_path_tiles()`**
- **Co to znamená:** Definuje funkci `create_path_tiles`, která nepřijímá žádné argumenty a nevrací žádnou hodnotu.
- **Účel:** Vytváří dlaždice cesty na základě vygenerovaných bodů cesty.

**`if path_points.size() == 0:`**
- **Co to znamená:** Kontroluje, zda je seznam `path_points` prázdný.
- **Účel:** Pokud neexistují žádné body cesty, tiskne zprávu a vrátí se.

**`print("No path points to create tiles")`**
- **Co to znamená:** Tiskne zprávu do konzole.
- **Účel:** Informuje, že neexistují žádné body cesty pro vytvoření dlaždic.

**`return`**
- **Co to znamená:** Ukončuje funkci.
- **Účel:** Vrací se, pokud neexistují žádné body cesty.

**`for i in range(path_points.size() - 1):`**
- **Co to znamená:** Prochází každý bod cesty kromě posledního.
- **Účel:** Vytváří dlaždice cesty mezi každým párem sousedních bodů cesty.

**`var start_point = path_points[i]`**
- **Co to znamená:** Nastaví `start_point` na bod cesty na indexu `i`.
- **Účel:** Uchovává počáteční bod segmentu cesty.

**`var end_point = path_points[i + 1]`**
- **Co to znamená:** Nastaví `end_point` na bod cesty na indexu `i + 1`.
- **Účel:** Uchovává koncový bod segmentu cesty.

**`print("Creating path segment from ", start_point, " to ", end_point)`**
- **Co to znamená:** Tiskne zprávu do konzole.
- **Účel:** Informuje o vytváření segmentu cesty.

**`create_path_segment(start_point, end_point)`**
- **Co to znamená:** Zavolá funkci `create_path_segment` s `start_point` a `end_point`.
- **Účel:** Vytváří segment cesty mezi `start_point` a `end_point`.

```gdscript
func create_path_segment(start: Vector3, end: Vector3):
    var direction = (end - start).normalized() * tile_size.length()
    var current_position = start

    while current_position.distance_to(start) < start.distance_to(end):
        var tile_instance = tile_scene.instantiate()
        if tile_instance == null:
            print("Failed to instantiate tile_scene")
            return
        tile_instance.transform.origin = current_position
        tile_instance.transform.origin.y = 0  # Udržet dlaždice na zemi
        add_child(tile_instance)
        current_position += direction

    # Add the last tile to ensure full coverage
    var last_tile_instance = tile_scene.instantiate()
    if last_tile_instance == null:
        print("Failed to instantiate last tile")
        return
    last_tile_instance.transform.origin = end
    last_tile_instance.transform.origin.y = 0  # Udržet dlaždice na zemi
    add_child(last_tile_instance)
```
**`func create_path_segment(start: Vector3, end: Vector3)`**
- **Co to znamená:** Definuje funkci `create_path_segment`, která přijímá vektory `start` a `end` a nevrací žádnou hodnotu.
- **Účel:** Vytváří segment cesty mezi `start` a `end`.

**`var direction = (end - start).normalized() * tile_size.length()`**
- **Co to znamená:** Nastaví `direction` na normalizovaný vektor z `start` do `end`, násobený délkou dlaždice.
- **Účel:** Určuje směr a délku pro vytváření dlaždic cesty.

**`var current_position = start`**
- **Co to znamená:** Nastaví `current_position` na `start`.
- **Účel:** Inicializuje aktuální pozici na počáteční bod segmentu cesty.

**`while current_position.distance_to(start) < start.distance_to(end):`**
- **Co to znamená:** Spustí cyklus, dokud je vzdálenost od `current_position` do `start` menší než vzdálenost od `start` do `end`.
- **Účel:** Vytváří dlaždice mezi `start` a `end`.

**`var tile_instance = tile_scene.instantiate()`**
- **Co to znamená:** Instanciuje `tile_scene` a uloží výsledek do `tile_instance`.
- **Účel:** Vytváří novou instanci dlaždice.

**`if tile_instance == null:`**
- **Co to znamená:** Kontroluje, zda `tile_instance` je null.
- **Účel:** Pokud se nepodařilo instancovat dlaždici, tiskne zprávu a vrátí se.

**`print("Failed to instantiate tile_scene")`**
- **Co to znamená:** Tiskne zprávu do konzole.
- **Účel:** Informuje o neúspěchu při instancování dlaždice.

**`return`**
- **Co to znamená:** Ukončuje funkci.
- **Účel:** Vrací se, pokud se nepodařilo instancovat dlaždici.

**`tile_instance.transform.origin = current_position`**
- **Co to znamená:** Nastaví pozici `tile_instance` na `current_position`.
- **Účel:** Umístí dlaždici na aktuální pozici.

**`tile_instance.transform.origin.y = 0`**
- **Co to znamená:** Nastaví y složku pozice `tile_instance` na 0.
- **Účel:** Udržuje dlaždici na zemi.

**`add_child(tile_instance)`**
- **Co to znamená:** Přidá `tile_instance` jako dítě k uzlu.
- **Účel:** Přidává dlaždici do scény.

**`current_position += direction`**
- **Co to znamená:** Přičte `direction` k `current_position`.
- **Účel:** Posune aktuální pozici o jednu dlaždici ve směru `direction`.

**`var last_tile_instance = tile_scene.instantiate()`**
- **Co to znamená:** Instanciuje `tile_scene` a uloží výsledek do `last_tile_instance`.
- **Účel:** Vytváří poslední instanci dlaždice.

**`if last_tile_instance == null:`**
- **Co to znamená:** Kontroluje, zda `last_tile_instance` je null.
- **Účel:** Pokud se nepodařilo instancovat dlaždici, tiskne zprávu a vrátí se.

**`print("Failed to instantiate last tile")`**
- **Co to znamená:** Tiskne zprávu do konzole.
- **Účel:** Informuje o neúspěchu při instancování poslední dlaždice.

**`return`**
- **Co to znamená:** Ukončuje funkci.
- **Účel:** Vrací se, pokud se nepodařilo instancovat dlaždici.

**`last_tile_instance.transform.origin = end`**
- **Co to znamená:** Nastaví pozici `last_tile_instance` na `end`.
- **Účel:** Umístí poslední dlaždici na koncovou pozici segmentu cesty.

**`last_tile_instance.transform.origin.y = 0`**
- **Co to znamená:** Nastaví y složku pozice `last_tile_instance` na 0.
- **Účel:** Udržuje dlaždici na zemi.

**`add_child(last_tile_instance)`**
- **Co to znamená:** Přidá `last_tile_instance` jako dítě k uzlu.
- **Účel:** Přidává poslední dlaždici do scény.

package robotname

import "core:fmt"
import "core:strings"
import "core:testing"
import "core:text/regex"
import "core:unicode/utf8"

seen := make(map[string]bool)

name_valid :: proc(name: string) -> bool {
	pat, err := regex.create(`^[A-Z]{2}\d{3}$`)
	defer regex.destroy(pat)
	if err != regex.Creation_Error.None {
		return false
	}
	captures, matched := regex.match(pat, name)
	defer regex.destroy(captures)
	return matched
}

@(test)
test_name_valid :: proc(t: ^testing.T) {
	storage := new_storage()
	defer delete_storage(&storage)
	r, e := new_robot(&storage)
	testing.expect(t, e == Error.None)
	testing.expect(t, name_valid(r.name))
}

@(test)
test_successive_robots_have_different_names :: proc(t: ^testing.T) {
	storage := new_storage()
	defer delete_storage(&storage)
	n1, e1 := new_robot(&storage)
	n2, e2 := new_robot(&storage)
	testing.expect(t, e1 == Error.None)
	testing.expect(t, e2 == Error.None)
	testing.expect(t, n1 != n2)
}

@(test)
test_reset_name :: proc(t: ^testing.T) {
	storage := new_storage()
	defer delete_storage(&storage)
	r, e := new_robot(&storage)
	n1 := r.name
	reset(&storage, &r)
	n2 := r.name
	testing.expect(t, e == Error.None)
	testing.expect(t, n1 != n2)
}

@(test)
test_multiple_names :: proc(t: ^testing.T) {
	storage := new_storage()
	defer delete_storage(&storage)
	for i := len(seen); i <= 1000; i += 1 {
		r, e := new_robot(&storage)
		testing.expect(t, e == Error.None)
		testing.expect(t, !seen[r.name])
		seen[r.name] = true
	}
}
fill_names :: proc(storage: ^RobotStorage) {
	State :: struct {
		ch:      rune,
		go_back: bool,
	}
	stack: [dynamic]State
	defer delete(stack)
	current := make([]rune, 5)
	defer delete(current)
	for c := 'A'; c <= 'Z'; c += 1 {
		append(&stack, State{c, false})
	}
	depth := 0
	for len(stack) > 0 {
		state := pop(&stack)
		ch := state.ch
		go_back := state.go_back
		if go_back {
			depth -= 1
			continue
		}
		current[depth] = ch
		depth += 1
		if depth == 5 {
			key := utf8.runes_to_string(current)
			storage.names[key] = true
			fmt.printfln("reserve '%s',", key)
			depth -= 1
			continue
		}
		append(&stack, State{ch, true})
		if depth < 2 {
			for c := 'A'; c <= 'Z'; c += 1 {
				append(&stack, State{c, false})
			}
		} else {
			for c := '0'; c <= '9'; c += 1 {
				append(&stack, State{c, false})
			}
		}
	}
}
@(test)
test_collisions :: proc(t: ^testing.T) {
	storage := new_storage()
	defer delete_storage(&storage)
	fill_names(&storage)
	r, e := new_robot(&storage)
	testing.expect_value(t, e, Error.CouldNotCreateName)
}


minetest.register_craft({
      type = "fuel",
      recipe = "citadella:chest",
      burntime = 30,
})


minetest.register_craft({
      output = "citadella:chest",
      recipe = {
         {'group:wood', 'group:wood', 'group:wood'},
         {'group:wood', ''          , 'group:wood'},
         {'group:wood', 'group:wood', 'group:wood'},
      }
})


function ct.make_open_formspec(reinf, group, name)
   local chest_title = name or "Chest"
   if reinf then
      chest_title = "Locked " .. chest_title .. " (group: '" .. group.name .. "', "
         .. tostring(reinf.material) .. ", " .. tostring(reinf.value) .. "/"
         .. tostring(ct.resource_limits[reinf.material]) .. ")"
   end

   local open = {
      "size[8,10]",
      "label[0,0;", chest_title, "]",
      -- default.gui_bg ,
      -- default.gui_bg_img ,
      -- default.gui_slots ,
      "list[current_name;main;0,0.7;8,4;]",
      "list[current_player;main;0,5.2;8,1;]",
      "list[current_player;main;0,6.3;8,3;8]",
      "listring[current_name;main]",
      "listring[current_player;main]",
      "button[3,9.35;2,1;open;Close]" -- ,
      -- default.get_hotbar_bg(0,4.85)
   }
   return table.concat(open, "")
end

function ct.make_closed_formspec()
   local closed = "size[2,0.75]"..
      "button[0,0.0;2,1;open;Open]"
   return closed
end

local prisonpearl = minetest.get_modpath("prisonpearl")

minetest.register_node(
   "citadella:chest",
   {
      description = "Chest",
      tiles ={"default_chest.png^[sheet:2x2:0,0", "default_chest.png^[sheet:2x2:0,0",
              "default_chest.png^[sheet:2x2:1,0", "default_chest.png^[sheet:2x2:1,0",
              "default_chest.png^[sheet:2x2:1,0", "default_chest.png^[sheet:2x2:1,1"},
      paramtype2 = "facedir",
      groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
      legacy_facedir_simple = true,
      is_ground_content = false,
      sounds = default.node_sound_wood_defaults(),
      on_construct = function(pos)
         local meta = minetest.get_meta(pos)
         meta:set_string("formspec", ct.make_closed_formspec())
         -- meta:set_string("infotext", "Locked chest")
         meta:set_string("owner", "")
         local inv = meta:get_inventory()
         inv:set_size("main", 8*4)
      end,
      after_dig_node = function(pos, old, meta, digger)
         local drops = {}
         for _, stack in ipairs(meta.inventory.main) do
            local item = stack:to_string()
            if item ~= "" then
               table.insert(drops, item)
            end
         end
         minetest.handle_node_drops(pos, drops, digger)
      end,
      allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
         local meta = minetest.get_meta(pos)
         if not ct.has_locked_chest_privilege(pos, player) then
            minetest.log("action", player:get_player_name()..
                            " tried to move in a locked chest at "..
                            minetest.pos_to_string(pos))
            return 0
         end
         return count
      end,
      allow_metadata_inventory_put = function(pos, listname, index, stack, player)
         local meta = minetest.get_meta(pos)
         if not ct.has_locked_chest_privilege(pos, player) then
            minetest.log("action", player:get_player_name()..
                            " tried to put into a locked chest at "..
                            minetest.pos_to_string(pos))
            return 0
         end
         return stack:get_count()
      end,
      allow_metadata_inventory_take = function(pos, listname, index, stack, player)
         local meta = minetest.get_meta(pos)
         if not ct.has_locked_chest_privilege(pos, player) then
            minetest.log("action", player:get_player_name()..
                            " tried to take from a locked chest at "..
                            minetest.pos_to_string(pos))
            return 0
         end
         return stack:get_count()
      end,
      on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
         minetest.log("verbose", player:get_player_name()..
                         " moves stuff in locked chest at "..minetest.pos_to_string(pos))
      end,
      on_metadata_inventory_put = function(pos, listname, index, stack, player)
         minetest.log("verbose", player:get_player_name()..
                         " moves stuff to locked chest at "..minetest.pos_to_string(pos))
      end,
      on_metadata_inventory_take = function(pos, listname, index, stack, player)
         minetest.log("verbose", player:get_player_name()..
                         " takes stuff from locked chest at "..minetest.pos_to_string(pos))
      end,
      on_receive_fields = function(pos, formname, fields, sender)
         local meta = minetest.get_meta(pos)
         local can_open, reinf, group = ct.has_locked_chest_privilege(pos, sender)
         if can_open then
            if fields.open == "Open" then
               meta:set_string("formspec", ct.make_open_formspec(reinf, group))
            else
               meta:set_string("formspec", ct.make_closed_formspec())
            end
         end
      end,
})

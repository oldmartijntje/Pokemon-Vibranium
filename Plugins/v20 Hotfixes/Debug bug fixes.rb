#===============================================================================
# Fixed some outdated code used in example map events.
#===============================================================================
module Compiler
  SCRIPT_REPLACEMENTS += [
    ["pbCheckAble",                  "$player.has_other_able_pokemon?"],
    ["$PokemonTemp.lastbattle",      "$game_temp.last_battle_record"],
    ["calcStats",                    "calc_stats"]
  ]
end

#===============================================================================
# Fixed error when the Compiler tries to convert some pbTrainerBattle code to
# TrainerBattle.start.
#===============================================================================
module Compiler
  module_function

  def split_string_with_quotes(str)
    ret = []
    new_str = ""
    in_msg = false
    str.scan(/./) do |s|
      if s == "," && !in_msg
        ret.push(new_str.strip)
        new_str = ""
      else
        in_msg = !in_msg if s == "\""
        new_str += s
      end
    end
    new_str.strip!
    ret.push(new_str) if !new_str.empty?
    return ret
  end

  def replace_old_battle_scripts(event, list, index)
    changed = false
    script = list[index].parameters[1]
    if script[/^\s*pbWildBattle\((.+)\)\s*$/]
      battle_params = split_string_with_quotes($1)   # Split on commas
      list[index].parameters[1] = sprintf("WildBattle.start(#{battle_params[0]}, #{battle_params[1]})")
      old_indent = list[index].indent
      new_events = []
      if battle_params[3] && battle_params[3][/false/]
        push_script(new_events, "setBattleRule(\"cannotRun\")", old_indent)
      end
      if battle_params[4] && battle_params[4][/true/]
        push_script(new_events, "setBattleRule(\"canLose\")", old_indent)
      end
      if battle_params[2] && battle_params[2] != "1"
        push_script(new_events, "setBattleRule(\"outcome\", #{battle_params[2]})", old_indent)
      end
      list[index, 0] = new_events if new_events.length > 0
      changed = true
    elsif script[/^\s*pbDoubleWildBattle\((.+)\)\s*$/]
      battle_params = split_string_with_quotes($1)   # Split on commas
      pkmn1 = "#{battle_params[0]}, #{battle_params[1]}"
      pkmn2 = "#{battle_params[2]}, #{battle_params[3]}"
      list[index].parameters[1] = sprintf("WildBattle.start(#{pkmn1}, #{pkmn2})")
      old_indent = list[index].indent
      new_events = []
      if battle_params[3] && battle_params[5][/false/]
        push_script(new_events, "setBattleRule(\"cannotRun\")", old_indent)
      end
      if battle_params[4] && battle_params[6][/true/]
        push_script(new_events, "setBattleRule(\"canLose\")", old_indent)
      end
      if battle_params[2] && battle_params[4] != "1"
        push_script(new_events, "setBattleRule(\"outcome\", #{battle_params[4]})", old_indent)
      end
      list[index, 0] = new_events if new_events.length > 0
      changed = true
    elsif script[/^\s*pbTripleWildBattle\((.+)\)\s*$/]
      battle_params = split_string_with_quotes($1)   # Split on commas
      pkmn1 = "#{battle_params[0]}, #{battle_params[1]}"
      pkmn2 = "#{battle_params[2]}, #{battle_params[3]}"
      pkmn3 = "#{battle_params[4]}, #{battle_params[5]}"
      list[index].parameters[1] = sprintf("WildBattle.start(#{pkmn1}, #{pkmn2}, #{pkmn3})")
      old_indent = list[index].indent
      new_events = []
      if battle_params[3] && battle_params[7][/false/]
        push_script(new_events, "setBattleRule(\"cannotRun\")", old_indent)
      end
      if battle_params[4] && battle_params[8][/true/]
        push_script(new_events, "setBattleRule(\"canLose\")", old_indent)
      end
      if battle_params[2] && battle_params[6] != "1"
        push_script(new_events, "setBattleRule(\"outcome\", #{battle_params[6]})", old_indent)
      end
      list[index, 0] = new_events if new_events.length > 0
      changed = true
    elsif script[/^\s*pbTrainerBattle\((.+)\)\s*$/]
      battle_params = split_string_with_quotes($1)   # Split on commas
      trainer1 = "#{battle_params[0]}, #{battle_params[1]}"
      trainer1 += ", #{battle_params[4]}" if battle_params[4] && battle_params[4] != "nil"
      list[index].parameters[1] = "TrainerBattle.start(#{trainer1})"
      old_indent = list[index].indent
      new_events = []
      if battle_params[2] && !battle_params[2].empty? && battle_params[2] != "nil"
        speech = battle_params[2].gsub(/^\s*_I\(\s*"\s*/, "").gsub(/\"\s*\)\s*$/, "")
        push_comment(new_events, "EndSpeech: #{speech.strip}", old_indent)
      end
      if battle_params[3] && battle_params[3][/true/]
        push_script(new_events, "setBattleRule(\"double\")", old_indent)
      end
      if battle_params[5] && battle_params[5][/true/]
        push_script(new_events, "setBattleRule(\"canLose\")", old_indent)
      end
      if battle_params[6] && battle_params[6] != "1"
        push_script(new_events, "setBattleRule(\"outcome\", #{battle_params[6]})", old_indent)
      end
      list[index, 0] = new_events if new_events.length > 0
      changed = true
    elsif script[/^\s*pbDoubleTrainerBattle\((.+)\)\s*$/]
      battle_params = split_string_with_quotes($1)   # Split on commas
      trainer1 = "#{battle_params[0]}, #{battle_params[1]}"
      trainer1 += ", #{battle_params[2]}" if battle_params[2] && battle_params[2] != "nil"
      trainer2 = "#{battle_params[4]}, #{battle_params[5]}"
      trainer2 += ", #{battle_params[6]}" if battle_params[6] && battle_params[6] != "nil"
      list[index].parameters[1] = "TrainerBattle.start(#{trainer1}, #{trainer2})"
      old_indent = list[index].indent
      new_events = []
      if battle_params[3] && !battle_params[3].empty? && battle_params[3] != "nil"
        speech = battle_params[3].gsub(/^\s*_I\(\s*"\s*/, "").gsub(/\"\s*\)\s*$/, "")
        push_comment(new_events, "EndSpeech1: #{speech.strip}", old_indent)
      end
      if battle_params[7] && !battle_params[7].empty? && battle_params[7] != "nil"
        speech = battle_params[7].gsub(/^\s*_I\(\s*"\s*/, "").gsub(/\"\s*\)\s*$/, "")
        push_comment(new_events, "EndSpeech2: #{speech.strip}", old_indent)
      end
      if battle_params[8] && battle_params[8][/true/]
        push_script(new_events, "setBattleRule(\"canLose\")", old_indent)
      end
      if battle_params[9] && battle_params[9] != "1"
        push_script(new_events, "setBattleRule(\"outcome\", #{battle_params[9]})", old_indent)
      end
      list[index, 0] = new_events if new_events.length > 0
      changed = true
    elsif script[/^\s*pbTripleTrainerBattle\((.+)\)\s*$/]
      battle_params = split_string_with_quotes($1)   # Split on commas
      trainer1 = "#{battle_params[0]}, #{battle_params[1]}"
      trainer1 += ", #{battle_params[2]}" if battle_params[2] && battle_params[2] != "nil"
      trainer2 = "#{battle_params[4]}, #{battle_params[5]}"
      trainer2 += ", #{battle_params[6]}" if battle_params[6] && battle_params[6] != "nil"
      trainer3 = "#{battle_params[8]}, #{battle_params[9]}"
      trainer3 += ", #{battle_params[10]}" if battle_params[10] && battle_params[10] != "nil"
      list[index].parameters[1] = "TrainerBattle.start(#{trainer1}, #{trainer2}, #{trainer3})"
      old_indent = list[index].indent
      new_events = []
      if battle_params[3] && !battle_params[3].empty? && battle_params[3] != "nil"
        speech = battle_params[3].gsub(/^\s*_I\(\s*"\s*/, "").gsub(/\"\s*\)\s*$/, "")
        push_comment(new_events, "EndSpeech1: #{speech.strip}", old_indent)
      end
      if battle_params[7] && !battle_params[7].empty? && battle_params[7] != "nil"
        speech = battle_params[7].gsub(/^\s*_I\(\s*"\s*/, "").gsub(/\"\s*\)\s*$/, "")
        push_comment(new_events, "EndSpeech2: #{speech.strip}", old_indent)
      end
      if battle_params[7] && !battle_params[7].empty? && battle_params[11] != "nil"
        speech = battle_params[11].gsub(/^\s*_I\(\s*"\s*/, "").gsub(/\"\s*\)\s*$/, "")
        push_comment(new_events, "EndSpeech3: #{speech.strip}", old_indent)
      end
      if battle_params[12] && battle_params[12][/true/]
        push_script(new_events, "setBattleRule(\"canLose\")", old_indent)
      end
      if battle_params[13] && battle_params[13] != "1"
        push_script(new_events, "setBattleRule(\"outcome\", #{battle_params[13]})", old_indent)
      end
      list[index, 0] = new_events if new_events.length > 0
      changed = true
    end
    return changed
  end
end

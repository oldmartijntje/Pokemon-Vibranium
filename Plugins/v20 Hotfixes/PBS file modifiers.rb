#===============================================================================
# Renamed trainer_types.txt property "VictoryME" to "VictoryBGM".
# Renamed moves.txt property "BaseDamage" to "Power".
#===============================================================================

module GameData
  class Move
    SCHEMA["Power"] = [:base_damage, "u"]
  end
end

module Compiler
  module_function

  def edit_and_rewrite_pbs_file_text(filename)
    return if !block_given?
    lines = []
    File.open(filename, "rb") { |f|
      f.each_line { |line| lines.push(line) }
    }
    changed = false
    lines.each { |line| changed = true if yield line }
    if changed
      Console.echo_h2("Changes made to file #{filename}.", text: :yellow)
      File.open(filename, "wb") { |f|
        lines.each { |line| f.write(line) }
      }
    end
  end

  def modify_pbs_file_contents_before_compiling
    edit_and_rewrite_pbs_file_text("PBS/trainer_types.txt") do |line|
      next line.gsub!(/^\s*VictoryME\s*=/, "VictoryBGM =")
    end
    edit_and_rewrite_pbs_file_text("PBS/moves.txt") do |line|
      ret = line.gsub!(/^\s*BaseDamage\s*=/, "Power =")
      ret ||= line.gsub!(/LowerTargetDefense1DoublePowerInGravity/, "LowerTargetDefense1PowersUpInGravity")
      next ret
    end
  end

  class << self
    alias __hotfixes__compile_pbs_files compile_pbs_files
  end

  def compile_pbs_files
    modify_pbs_file_contents_before_compiling
    __hotfixes__compile_pbs_files
  end
end

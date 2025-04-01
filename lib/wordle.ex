defmodule Wordle do
  @moduledoc """
  Documentation for `Wordle`.
  """

  # result tiles
  # green = right letter, right position
  # yellow = right letter, wrong position
  # grey = not in word

  defp decrease_freq_for_green(result, freq) do
    Enum.reduce(result, freq, fn {letter, _idx, color}, acc ->
      case color do
        :green -> Map.update!(acc, letter, fn x -> x - 1 end)
        _ -> acc
      end
    end)
  end

  def check_green(guess, word) do
    guess_indices = guess |> String.graphemes() |> Enum.with_index()
    word_indices = word |> String.graphemes() |> Enum.with_index()

    # check if the letters are in the same position
    result =
      Enum.zip(
        guess_indices,
        word_indices
      )
      |> Enum.map(fn {{guess_letter, guess_idx}, {word_letter, _word_idx}} ->
        {guess_letter, guess_idx, guess_letter == word_letter}
      end)
      |> Enum.map(fn {guess_letter, guess_index, guess_result} ->
        case guess_result do
          true -> {guess_letter, guess_index, :green}
          false -> {guess_letter, guess_index, :grey}
        end
      end)

    # update remaining frequencies
    # by subtracting the used letters that are `green`
    word_freq = word |> String.graphemes() |> Enum.frequencies()

    remaining_freq = decrease_freq_for_green(result, word_freq)

    {result, remaining_freq}
  end

  defp update_yellow_result(result, letter, idx, color) do
    new_result = [{letter, idx, :yellow} | result] -- [{letter, idx, color}]

    # sort the result by index
    new_result =
      Enum.sort_by(new_result, fn {_letter, idx, _color} -> idx end)

    new_result
  end

  def check_yellow(result, remaining_freq) do
    Enum.reduce(result, {result, remaining_freq}, fn
      {letter, idx, color}, {old_res, old_freq} ->
        case color do
          :green ->
            # If the color is green, no changes are needed
            {old_res, old_freq}

          :grey ->
            # if the color is grey, check if it can be yellow?
            letter_freq = Map.get(old_freq, letter)

            case letter_freq do
              nil ->
                # no in the map = grey
                {old_res, old_freq}

              0 ->
                # no more frequency left = grey
                {old_res, old_freq}

              _ ->
                # otherwise, it can be yellow
                # update the result and decrease the frequency
                {
                  update_yellow_result(old_res, letter, idx, color),
                  Map.update!(old_freq, letter, fn x -> x - 1 end)
                }
            end
        end
    end)
  end

  def analyse(%{guess: guess, word: word}) do
    {result, freq} = check_green(guess, word)
    {result, _freq} = check_yellow(result, freq)
    result
  end

  def analyse_only_color(%{guess: guess, word: word}) do
    result = analyse(%{guess: guess, word: word})

    Enum.map(result, fn r -> r |> Tuple.to_list() |> Enum.at(2) end)
  end

  def encode_result(result, mode) do
    case mode do
      :tile ->
        result
        |> Enum.map(fn
          :green -> "🟩"
          :yellow -> "🟨"
          :grey -> "⬛"
        end)
        |> Enum.join("")

      _ ->
        result
        |> Enum.map(fn
          :green -> "g"
          :yellow -> "y"
          :grey -> "b"
        end)
        |> Enum.join("")
    end
  end
end

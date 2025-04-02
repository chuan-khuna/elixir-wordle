defmodule Wordle do
  @moduledoc """
  Documentation for `Wordle`.
  """

  # result tiles
  # green = right letter, right position
  # yellow = right letter, wrong position
  # grey = not in word

  defp init_letter_frequency(result, freq) do
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

    # decrese the frequency of the letters that are green
    remaining_freq = init_letter_frequency(result, word_freq)

    {result, remaining_freq}
  end

  defp update_result(result, letter, idx) do
    # update the result at the index to yellow
    result
    |> Enum.map(fn
      {^letter, ^idx, _} -> {letter, idx, :yellow}
      other -> other
    end)
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
                  update_result(old_res, letter, idx),
                  Map.update!(old_freq, letter, fn x -> x - 1 end)
                }
            end
        end
    end)
  end

  def analyse(%{guess: guess, word: word}, return_only_color \\ false) do
    {result, freq} = check_green(guess, word)
    {result, _freq} = check_yellow(result, freq)

    case return_only_color do
      true -> Enum.map(result, fn r -> r |> Tuple.to_list() |> Enum.at(2) end)
      false -> result
    end
  end

  def encode_result(result, mode \\ :letter) do
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

  def decode_result(result, mode \\ :letter) do
    case mode do
      :tile ->
        result
        |> String.graphemes()
        |> Enum.map(fn
          "🟩" -> :green
          "🟨" -> :yellow
          "⬛" -> :grey
        end)

      _ ->
        result
        |> String.graphemes()
        |> Enum.map(fn
          "g" -> :green
          "y" -> :yellow
          "b" -> :grey
        end)
    end
  end
end

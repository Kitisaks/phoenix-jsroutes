defmodule TestHelper do
  @moduledoc false
  import ExUnit.Assertions

  # Stub controllers so Phoenix 1.8+ route verification does not warn in tests.
  for name <- [
        ProductController,
        OrderController,
        PageController,
        UserController,
        AdminController
      ] do
    defmodule name do
      def init(opts), do: opts
      def call(conn, _opts), do: conn
    end
  end

  @doc """
  Asserts file exists in the filesystem
  """
  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  @doc """
  Asserts that file exists and its contents are matched by `match`.
  `match` can be a binary, a regex or a list. If it's a list, every member of the list
  must match with the file contents.
  """
  def assert_file(file, match) when is_list(match) do
    assert_file(file, &Enum.each(match, fn m -> assert &1 =~ m end))
  end

  def assert_file(file, match) when is_binary(match) or is_map(match) do
    assert_file(file, &assert(&1 =~ match))
  end

  @doc """
  Assert that file exists and pass its contents to a function for further assertions.
  """
  def assert_contents(file, match) when is_function(match, 1) do
    assert_file(file)
    match.(File.read!(file))
  end

  @doc """
  Assert that a file does NOT exist.
  """
  def refute_file(file) do
    refute File.regular?(file), "Expected #{file} to not exist, but it does"
  end

  # Creates a unique folder for every test to avoid
  # that the result of one test afects another
  def unique_id do
    System.unique_integer([:positive])
  end

  def path(folder, name) do
    Path.join(folder, name)
  end
end

defmodule TestFolderSupport do
  @moduledoc false
  use ExUnit.CaseTemplate

  setup tags do
    if tags[:clean_folder] do
      folder = "tmp/#{TestHelper.unique_id()}"
      File.mkdir_p(folder)

      on_exit(fn ->
        File.rm_rf(folder)
      end)

      {:ok, folder: folder}
    else
      :ok
    end
  end
end

# Get Mix output sent to the current
# process to avoid polluting tests.
Mix.shell(Mix.Shell.Process)

ExUnit.start()

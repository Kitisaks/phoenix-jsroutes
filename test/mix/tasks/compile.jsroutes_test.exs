defmodule Mix.RouterTest do
  use Phoenix.Router

  scope "/api" do
    get("/products", ProductController, :index)
    put("/orders/:id", OrderController, :update)
    resources("/admin", AdminController)
  end

  get("/", PageController, :index, as: :page)
  resources("/users", UserController)
end

defmodule Mix.Tasks.Compile.JsroutesTest do
  use ExUnit.Case, async: false
  use TestFolderSupport

  import TestHelper

  alias Mix.Tasks.Compile.Jsroutes

  @tag :clean_folder
  test "allows to configure the output path", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      Jsroutes.run(["--router", "Mix.RouterTest"])
      assert_file(path(folder, "phoenix-jsroutes.js"))
    end)
  end

  test "generates a valid javascript module" do
    folder = System.tmp_dir!()

    run_with_env([output_folder: folder], fn ->
      Jsroutes.run(["--router", "Mix.RouterTest"])

      original_file = path(folder, "phoenix-jsroutes.js")
      compiled_file = path(folder, "bundle.js")

      assert_file(original_file)

      {_, 0} =
        System.cmd(
          "npx",
          [
            "rollup",
            original_file,
            "--file",
            compiled_file,
            "--format",
            "iife",
            "--name",
            "routes",
            "--silent"
          ],
          stderr_to_stdout: true
        )

      assert call_route(compiled_file, "userIndex", []) == "/users"
      assert call_route(compiled_file, "userCreate", []) == "/users"
      assert call_route(compiled_file, "userUpdate", [1]) == "/users/1"
      assert call_route(compiled_file, "userDelete", [1]) == "/users/1"
      assert call_route(compiled_file, "userEdit", [1]) == "/users/1/edit"

      assert call_route(compiled_file, "productIndex", []) == "/api/products"
      assert call_route(compiled_file, "orderUpdate", [1]) == "/api/orders/1"

      File.rm(original_file)
      File.rm(compiled_file)
    end)
  end

  @tag :clean_folder
  test "ignore the first argument when it is not a valid module name", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      assert_raise(Mix.Error, "module Elixir.NotFound was not loaded and cannot be loaded", fn ->
        Jsroutes.run(["--router", "NotFound"])
      end)
    end)
  end

  @tag :clean_folder
  test "allows to filter urls", %{folder: folder} do
    run_with_env([output_folder: folder, include: ~r[api/], exclude: ~r[/admin]], fn ->
      Jsroutes.run(["--router", "Mix.RouterTest"])

      assert_contents(path(folder, "phoenix-jsroutes.js"), fn file ->
        refute file =~ "page"
        refute file =~ "user"
        refute file =~ "admin"

        assert file =~ "productIndex() {"
        assert file =~ "return `/api/products`;"

        assert file =~ "orderUpdate(id) {"
        assert file =~ "return `/api/orders/${id}`;"
      end)
    end)
  end

  @tag :clean_folder
  test "clean up compilation artifacts", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      Jsroutes.run(["--router", "Mix.RouterTest"])
      assert_file(path(folder, "phoenix-jsroutes.js"))
      Jsroutes.clean()
      refute_file(path(folder, "phoenix-jsroutes.js"))
    end)
  end

  @tag :clean_folder
  test "forces compilation", %{folder: folder} do
    run_with_env([output_folder: folder], fn ->
      Jsroutes.run(["--router", "Mix.RouterTest"])
      File.rm(path(folder, "phoenix-jsroutes.js"))
      Jsroutes.run(["--router", "Mix.RouterTest", "--force"])
      assert_file(path(folder, "phoenix-jsroutes.js"))
    end)
  end

  defp run_with_env(env, fun) do
    Application.put_env(:phoenix_jsroutes, :jsroutes, env)
    fun.()
  after
    Application.put_env(:phoenix_jsroutes, :jsroutes, nil)
  end

  defp call_route(bundle_path, fun, args) do
    script = """
    const fs = require('fs');
    const code = fs.readFileSync(process.env.BUNDLE, 'utf8');
    const routes = new Function(`${code}; return routes;`)();
    const result = routes[process.env.FUN](...JSON.parse(process.env.ARGS));
    process.stdout.write(JSON.stringify(result));
    """

    {output, 0} =
      System.cmd("node", ["-e", script],
        env: [
          {"BUNDLE", bundle_path},
          {"FUN", fun},
          {"ARGS", encode_js_args(args)}
        ]
      )

    decode_js_string(output)
  end

  defp encode_js_args(args) do
    "[" <> Enum.map_join(args, ",", &to_string/1) <> "]"
  end

  defp decode_js_string(output) do
    output
    |> String.trim()
    |> String.trim("\"")
  end
end

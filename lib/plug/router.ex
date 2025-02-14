defmodule Francis.Plug.Router do
  defmacro __using__(opts) do
    quote location: :keep do
      import Francis

      @plug_router_to %{}
      @before_compile Plug.Router

      use Plug.Builder, unquote(opts)
      import Plug.Router, except: [get: 2, post: 2, put: 2, delete: 2, patch: 2]

      @doc false
      def match(conn, _opts) do
        do_match(conn, conn.method, Plug.Router.Utils.decode_path_info!(conn), conn.host)
      end

      @doc false
      def dispatch(%Plug.Conn{} = conn, opts) do
        {path, fun} = Map.fetch!(conn.private, :plug_route)

        try do
          :telemetry.span(
            [:plug, :router_dispatch],
            %{conn: conn, route: path, router: __MODULE__},
            fn ->
              conn = fun.(conn, opts)
              {conn, %{conn: conn, route: path, router: __MODULE__}}
            end
          )
        catch
          kind, reason ->
            Plug.Conn.WrapperError.reraise(conn, kind, reason, __STACKTRACE__)
        end
      end
    end
  end
end

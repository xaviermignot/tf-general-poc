using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
  options.KnownNetworks.Clear();
  options.KnownProxies.Clear();
  options.ForwardedHeaders = ForwardedHeaders.XForwardedHost;
  options.ForwardedForHeaderName = "X-ORIGINAL-HOST";
});

var app = builder.Build();

app.MapGet("/", () => "Hello World!");

app.MapGet("/hello", (HttpRequest req) => Results.Json(new { Headers = req.Headers.ToDictionary(h => h.Key, h => h.Value.ToString()) }));

app.Run();

using DojoApiDemo.Models;
using System;
using System.Configuration;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace DojoApiDemo
{
    class Program
    {
        static void Main()
        {
            RunAsync().Wait();
        }

        static async Task RunAsync()
        {
            using (var client = new HttpClient())
            {
                var form = new Dictionary<string, string>
                {
                    {"client_id",  ConfigurationManager.AppSettings["client_id"]},
                    {"client_secret",  ConfigurationManager.AppSettings["client_secret"]}
                };
                Console.WriteLine("...Testing POST api/oauth/token");
                var tokenRes = await client.PostAsync("https://dojo-rc.zenedge.com/api/oauth/token", new FormUrlEncodedContent(form));

                if (!tokenRes.IsSuccessStatusCode)
                {
                    Console.WriteLine("There was an error generating an access token");
                    return;
                }

                var token = await tokenRes.Content.ReadAsAsync<Token>(new[] { new JsonMediaTypeFormatter() });

                Console.WriteLine("Got access token: {0}", token.AccessToken);

                var demoWebApp = new Webapp
                {
                    Domain = "demowebapp.net",
                    OriginServers = new List<OriginServer>
                    {
                        new OriginServer
                        {
                            Ip = "222.111.222.111",
                            Port = 3456,
                            Weight = 1
                        }
                    }
                };

                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token.AccessToken);
                Console.WriteLine("...Testing POST api/v2/webapps");
                var authRes = await client.PostAsJsonAsync("https://dojo-rc.zenedge.com/api/v2/webapps", demoWebApp);
                if (!authRes.IsSuccessStatusCode)
                {
                    Console.WriteLine("There was an error creating a webapp, maybe it already exists");
                    return;
                }

                var webappRes = await authRes.Content.ReadAsAsync<WebappResponse>(new[] { new JsonMediaTypeFormatter() });
                Console.WriteLine("Created webapp with id: {0}", webappRes.Id);

                var demoPurge = new PurgeAll
                {
                    WebappDomain = "demowebapp.net"
                };

                Console.WriteLine("...Testing PUT api/v2/webapps/<webapp_id>/purge_all");
                authRes = await client.PutAsJsonAsync(string.Format("https://dojo-rc.zenedge.com/api/v2/webapps/{0}/purge_all", webappRes.Id), demoPurge);

                if (!authRes.IsSuccessStatusCode)
                {
                    Console.WriteLine("There was an error purging the cash");
                    return;
                }

                var taskRes = await authRes.Content.ReadAsAsync<TaskResponse>(new[] { new JsonMediaTypeFormatter() });
                Console.WriteLine("Purge all webapp cache task id: {0}", taskRes.TaskId);

                Console.WriteLine("...Testing DELETE api/v2/webapps/<webapp_id>");
                authRes = await client.DeleteAsync(string.Format("https://dojo-rc.zenedge.com/api/v2/webapps/{0}", webappRes.Id));

                if (!authRes.IsSuccessStatusCode)
                {
                    Console.WriteLine("There was an error deleting the webapp");
                    return;
                }

                taskRes = await authRes.Content.ReadAsAsync<TaskResponse>(new[] { new JsonMediaTypeFormatter() });
                Console.WriteLine("Deleting webapp task id: {0}", taskRes.TaskId);
            }
        }
    }
}
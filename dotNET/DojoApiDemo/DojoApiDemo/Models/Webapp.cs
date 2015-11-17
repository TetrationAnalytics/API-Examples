using Newtonsoft.Json;
using System.Collections.Generic;

namespace DojoApiDemo.Models
{
    public class Webapp
    {
        [JsonProperty("domain")]
        public string Domain { get; set; }
        [JsonProperty("origin_servers")]
        public List<OriginServer> OriginServers { get; set; }
    }
}

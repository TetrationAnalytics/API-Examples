using Newtonsoft.Json;

namespace DojoApiDemo.Models
{
    public class OriginServer
    {
        [JsonProperty("ip")]
        public string Ip { get; set; }
        [JsonProperty("port")]
        public int Port { get; set; }
        [JsonProperty("weight")]
        public int Weight { get; set; }
    }
}

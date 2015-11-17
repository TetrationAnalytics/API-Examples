using Newtonsoft.Json;

namespace DojoApiDemo.Models
{
    public class PurgeAll
    {
        [JsonProperty("webapp_domain")]
        public string WebappDomain { get; set; }
    }
}

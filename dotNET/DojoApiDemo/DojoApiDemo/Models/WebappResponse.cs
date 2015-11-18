using Newtonsoft.Json;

namespace DojoApiDemo.Models
{
    public class WebappResponse
    {
        [JsonProperty("id")]
        public string Id { get; set; }
    }
}

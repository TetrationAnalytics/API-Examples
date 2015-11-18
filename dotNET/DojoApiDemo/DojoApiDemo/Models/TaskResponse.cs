using Newtonsoft.Json;

namespace DojoApiDemo.Models
{
    public class TaskResponse
    {
        [JsonProperty("status")]
        public string Status { get; set; }
        [JsonProperty("task_id")]
        public string TaskId { get; set; }
    }
}

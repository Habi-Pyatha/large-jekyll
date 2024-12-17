document.getElementById("boardForm").addEventListener("submit",function(event){
    event.preventDefault();
    const boardName=document.getElementById("boardName").value;
    const apiKey =ENV["TRELLO_API_KEY"];
    const apiToken=ENV["TRELLO_TOKEN"]

    const url = `https://api.trello.com/1/boards/?name=${encodeURIComponent(boardName)}&key=${apiKey}&token=${apiToken}`;

    fetch(url,{
        method: "POST",
    })
    .then(response=>{
        if(response.ok){
            return response.json();
        }else{
            throw new Error("Failed to create board. Check your API key and token.");
        }
    })
    .then(data=>{
        alert(`Board created successfully! Board ID: ${data.id}`)
        console.log("Success",data);
    })
    .catch(error=>{
        alert("Error:" + error.message);
        console.error("Error:",error);
    })
})
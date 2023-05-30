import Graphics
import This
import Communication
import string
import json
import Softwares

var Client = Communication.WiFi_Client_Type()

var API_Key = ""

var Execute = true

# - Location

var Latitude = 0
var Longitude = 0

# - Graphics

var Window = This.Get_Window()
var Software = This.Get_This()

var Keyboard = Graphics.Keyboard_Type()

var First_Row = Graphics.Object_Type()
var City_Text_Area = Graphics.Text_Area_Type()
var Refresh_Button = Graphics.Button_Type()

var Weather_Label = Graphics.Label_Type()
var Temperature_Label = Graphics.Label_Type()
var Humidity_Label = Graphics.Label_Type()
var Wind_Label = Graphics.Label_Type()
var Cloudiness_Label = Graphics.Label_Type()

def Set_Interface_Button(Parent, Button, Text)
    Button.Create(Parent)
    Button.Add_Event(Software, Graphics.Event_Code_Clicked)

    Label = Graphics.Label_Type()
    Label.Create(Button)
    Label.Set_Text(Text)
end

def Set_Interface_Label(Parent, Label, Text)
    Label.Create(Parent)
    Label.Set_Text(Text)
end

def Set_Interface_Row(Parent, Row)
    Row.Create(Parent)
    Row.Set_Height(Graphics.Size_Content)
    Row.Set_Width(Graphics.Get_Percentage(100))
    Row.Set_Flex_Flow(Graphics.Flex_Flow_Row)
    Row.Set_Flex_Alignment(Graphics.Flex_Alignment_Space_Evenly, Graphics.Flex_Alignment_Center, Graphics.Flex_Alignment_Center)
	Row.Set_Style_Pad_All(0, 0)
end


def Set_Interface()
    Window.Set_Title("Weather")

    Window_Body = Window.Get_Body()
    Window_Body.Set_Flex_Flow(Graphics.Flex_Flow_Column)
    Window_Body.Set_Flex_Alignment(Graphics.Flex_Alignment_Space_Evenly, Graphics.Flex_Alignment_Center, Graphics.Flex_Alignment_Center)

    Keyboard.Create(Window_Body)
    Keyboard.Add_Flag(Graphics.Flag_Floating)
    Keyboard.Add_Flag(Graphics.Flag_Hidden)

    Set_Interface_Row(Window_Body, First_Row)
    City_Text_Area.Create(First_Row)
    City_Text_Area.Set_One_Line(true)
    City_Text_Area.Set_Placeholder_Text("City")
    City_Text_Area.Add_Event(Software, Graphics.Event_Code_Focused)
    City_Text_Area.Add_Event(Software, Graphics.Event_Code_Defocused)
    City_Text_Area.Set_Text("Paris")
    Set_Interface_Button(First_Row, Refresh_Button, "Refresh")

    Set_Interface_Label(Window_Body, Weather_Label, "Weather : ")
    Set_Interface_Label(Window_Body, Temperature_Label, "Temperature : ")
    Set_Interface_Label(Window_Body, Humidity_Label, "Humidity : ")
    Set_Interface_Label(Window_Body, Wind_Label, "Wind : ")
    Set_Interface_Label(Window_Body, Cloudiness_Label, "Cloudiness : ")
end

def Refresh_City_Coordinate()
    if Client.Connect("api.openweathermap.org", 443, 4750) == false
        return
    end

    Client.Write_String("GET https://api.openweathermap.org/geo/1.0/direct?q=" + City_Text_Area.Get_Text() + "&limit=1&appid=" + API_Key + "\n")
    Client.Write_String("Host: api.openweathermap.org\n")
    Client.Write_String("Connection: close\n")
    Client.Write_String("\n")
    
    Response = ""

    while Client.Connected()
        if Client.Available() > 0
            Response += string.char(Client.Read())
        end
    end

    Client.Stop()

    Parsed_Response = json.load(Response)

    if Parsed_Response == nil
        return
    end

    Latitude = Parsed_Response[0]["lat"]
    Longitude = Parsed_Response[0]["lon"]
end

def Refresh_Weather()
    if Client.Connect("api.openweathermap.org", 443, 4750) == false
        return
    end
        
    Client.Write_String("GET https://api.openweathermap.org/data/2.5/weather?lat=" + str(Latitude) + "&lon=" + str(Longitude) + "&appid=" + API_Key + "\n")
    Client.Write_String("Host: api.openweathermap.org\n")
    Client.Write_String("Connection: close\n")
    Client.Write_String("\n")
    
    Response = ""
    
    while Client.Connected()
        if Client.Available() > 0
            Response += string.char(Client.Read())
        end
    end
    
    Client.Stop()
    
    Parsed_Response = json.load(Response)

    if Parsed_Response == nil
        return
    end

    Weather_Label.Set_Text("Weather : " + Parsed_Response["weather"][0]["description"])
    Temperature_Label.Set_Text("Temperature : " + str(Parsed_Response["main"]["temp"] - 273.15) + "°C (" + str(Parsed_Response["main"]["temp_min"] - 273.15) + "°C - " + str(Parsed_Response["main"]["temp_max"] - 273.15) + "°C)")
    Humidity_Label.Set_Text("Humidity : " + str(Parsed_Response["main"]["humidity"]) + "%")
    Wind_Label.Set_Text("Wind : " + str(Parsed_Response["wind"]["speed"]) + " m/s - " + str(Parsed_Response["wind"]["deg"]) + "°")
    Cloudiness_Label.Set_Text("Cloudiness : " + str(Parsed_Response["clouds"]["all"]) + "%")
end

def Execute_Instruction(Instruction)

    if Instruction.Get_Sender() == Graphics.Get_Pointer()
        Target = Instruction.Graphics_Get_Target()
        if Target == Refresh_Button
            if Instruction.Graphics_Get_Code() == Graphics.Event_Code_Clicked
                Refresh_City_Coordinate()
                This.Delay(100)
                Refresh_Weather()
            end
        elif Target == City_Text_Area
            if Instruction.Graphics_Get_Code() == Graphics.Event_Code_Focused
                Keyboard.Set_Text_Area(City_Text_Area)
                Keyboard.Move_Foreground()
                Keyboard.Clear_Flag(Graphics.Flag_Hidden)
            elif Instruction.Graphics_Get_Code() == Graphics.Event_Code_Defocused
                Keyboard.Add_Flag(Graphics.Flag_Hidden)
                Keyboard.Remove_Text_Area()
            end
        end
    elif Instruction.Get_Sender() == Softwares.Get_Pointer()
        if Instruction.Softwares_Get_Code() == Softwares.Event_Code_Close
            Execute = false
        end
    end
end

Set_Interface()

Client.Set_Insecure()

while Execute
    if This.Instruction_Available() > 0
        Execute_Instruction(This.Get_Instruction())
    end

    This.Delay(50)
end
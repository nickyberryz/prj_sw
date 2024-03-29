class RoomsController < ApplicationController
  

  # welcome page 
  def index
    @welcomes_choose = Welcome.find_all_by_choose(true)
    @roomtype = DetailRoom.all_types
    @time = Room.all_times
    @day_list = Room.all_days
    @admin = session[:admin]
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @rooms }
    end
  end

  #show one room from search_result page
  def show
    @roomtype = DetailRoom.all_types
    @admin = session[:admin]
    @time = Room.all_times
    @day_list = Room.all_days
    @room = Room.find(params[:id])
    @size = DetailRoom.find_by_roomname(@room.roomname).amount
    @room_tool = Tool.find_by_roomname(@room.roomname)
    session[:id_room] = @room.id
    @date_select = session[:date_select]
    @time_select = session[:time_select]
  end

  #new room page
  def new
    if session[:admin] == nil
      redirect_to rooms_path
    else
      @roomtype = DetailRoom.all_types
      @box_times = Room.all_times
      @time = Room.all_times
      @day_list = Room.all_days
      @room = Room.new
 
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @room }
      end
    end
  end

  # edit room page
  def edit
    if session[:admin] == nil
      redirect_to rooms_path
    else
      @roomtype = DetailRoom.all_types
      @droom = DetailRoom.find(params[:id])
      @rooms= Room.find_all_by_roomname(@droom.roomname)
      @tool = Tool.find(params[:id])
      @time = Room.all_times
      @day_list = Room.all_days
      @box_times = Room.time_to_section
    end
  end

  
  # Add new room
  def create
    droom = params[:droom]
    if DetailRoom.find_by_roomname(droom["roomname"]) == nil
      droom["amount"] = params[:droom]["amount"]
      droom["room_type"] = params[:droom]["room_type"]
      @detail_room_obj = DetailRoom.new(droom)
      if @detail_room_obj.valid? && @detail_room_obj.save
        all_day = Room.all_days
        all_times = Room.all_times
        time_to_section = Room.time_to_section
        all_day.each do |d|
          room = {}
          room["day"] = d
          all_times.each do |t|
            if params[d][t] == "1"
              room[time_to_section[0][t]] = "busy"
            else
              room[time_to_section[0][t]] = "free"
            end
          end
          room["roomname"] = params[:droom]["roomname"]
          @room_obj = Room.new(room)
          @room_obj.save
        end
        tool = params[:tool]
        tool["roomname"] = params[:droom]["roomname"]
        @room_tool = Tool.new(tool)
        if @room_tool.save
          flash[:notice] = "add new room successess"
          redirect_to staffs_path
        else
          flash[:notice] = "can not add new tool"
          redirect_to staffs_path
        end
      else
        flash[:notice] = "can not add new room, please insert all value"
        redirect_to new_rooms_path 
      end
    else
      flash[:notice] = "can not add new droom"
      redirect_to staffs_path 
    end
   
  end

 
  
  # update room
  def update
    @roomtype = DetailRoom.all_types
    @time = Room.all_times
    @day_list = Room.all_days
    @box_times = Room.time_to_section
    @droom = DetailRoom.find(params[:id])
    old_name = DetailRoom.find(params[:id]).roomname
    if DetailRoom.find_by_roomname(params[:droom]["roomname"]) == nil
      @day_list.each do |day|
        temp_room = {}
        temp_room["roomname"] = params[:droom]["roomname"]
        temp_room["day"] = day
        @box_times[0].each do |time|
          if params[day][time[1]] == "1"
            temp_room[time[1]] = "busy"
          else
            temp_room[time[1]] = "free"
          end
        end
        res = Room.find_all_by_roomname(old_name)
        @room = res.select do |r|  r.day == day  end
        @room[0].update_attributes!(temp_room)
      end
      tool = params[:tool]
      tool["roomname"] = params[:droom]["roomname"]
      @room_tool = Tool.find_by_roomname(old_name)
      @room_tool.update_attributes!(tool)
      @droom.update_attributes!(params[:droom])
      flash[:notice] = "update room sucessfully"
      redirect_to staff_path(@droom)
    else
      flash[:notice] = "Can not modify roomname,Already roomname in database"
      redirect_to room_list_staffs_path
    end
    
  end

  
  # delete room
  def destroy
    @roomtype = DetailRoom.all_types
    @time = Room.all_times
    @day_list = Room.all_days
    @droom = DetailRoom.find(params[:id])
    roomname = @droom.roomname
    @day_list.each do |day|
      @room = Room.find_all_by_roomname(@droom.roomname)
      @room = @room.select do |i| i.day==day end
      @room[0].destroy
    end
    @tool = Tool.find(params[:id])
    @tool.destroy
    @droom.destroy
    flash[:notice] = "Delete success"
    redirect_to room_list_staffs_path
    
  end
  
  #search page
  def search
  @time = Room.all_times
  @day_list = Room.all_days
  @roomtype = DetailRoom.all_types
  @admin = session[:admin]
  end


  def search_result
    @roomtype = DetailRoom.all_types
    @time = Room.all_times
    @day_list = Room.all_days
    time_index = Room.time_to_section
    time_index = time_index[0][params[:section]["sec"]]
    @time_select = params[:section]["sec"]
    @size_select = params[:amount][:amount]
    day = params[:date]["day"]
    month = params[:date]["month"]
    date_str = params[:date]["year"]+"-"+ month.rjust(2,'0')+"-"+day.rjust(2,'0')
    @date_select = date_str
    if date_str < Date.today.to_s
      flash[:notice] = "Can not reserve room with date past"
      redirect_to search_path
    elsif date_str == Date.today.to_s && session[:admin] == nil
      flash[:notice] = "Can not reserve room with date today, please contact staff"
      redirect_to search_path
    else
      day_str = Date.parse date_str
      day_str = day_str.strftime("%A")
      time_str = @time_select.split("-")
      @free_rooms = DetailRoom.find_with_type(params[:room_type]["type"])
      @free_rooms = Room.find_with_day_sec(@free_rooms,day_str.downcase,time_index)
      @free_rooms = Room.find_with_datetime(@free_rooms,date_str,time_str[0],time_str[1])
      if @size_select != ""
        @free_rooms = Room.find_with_amount(@free_rooms,@size_select)
      else
        @size_select = "-"
      end
      if @free_rooms == []
        flash[:notice] = "Can not found available room"
        redirect_to search_path
      else
        @size = []
        @free_rooms.each_with_index do |room,i|
          @size[i] = DetailRoom.find_by_roomname(room.roomname).amount
        end
        session[:time_select] = @time_select
        session[:date_select] = @date_select
 
      end
    end
  end

  def search_box

    @temp_params = { "amount"=>{"amount"=>params[:amount_box][:amount_box]}, "room_type"=>{"type"=>params[:room_type]["type_box"]}, "date"=>{"year"=>params[:date_box]["year"], "month"=>params[:date_box]["month"], "day"=>params[:date_box]["day"]}, "section"=>{"sec"=>params[:section][:sec_box]}, "commit"=>"search room"}
    redirect_to search_result_path(@temp_params)

    #redirect_to about_path
  end
  
end

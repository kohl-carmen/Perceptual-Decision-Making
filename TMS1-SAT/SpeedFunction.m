function total_reward=SpeedFunction(coherence_order, direction_order, x_centre, y_centre, window, white,ifi,window_rect,buttons,deg,File2, bin_order, tms_bins, bin_interval, coherence, File1, nr_trials,instr_order)
%Speed Condition

%% Instruction Screen
Screen('TextFont',window,'Times');
Screen('TextSize',window, 20);
text='From now on, it is really important that you try to respond as quickly as possible. \n\n You will be given points for your performance. \n\n \n\n Like before, please look at the fixation cross in the middle of the screen \n\n and indicate the direction of the movement as quickly as possible.\n\n \n\n (Press any key to start)';
DrawFormattedText(window,text,'center','center',white);
vbl=Screen('Flip',window);
KbStrokeWait;

%% Initialise    
total_reward=0;
signal_duration=2;

% Deadline Staircase
q_speed=QuestCreate(0.6, 0.15, 0.75, 3.5,0.01, 0.5);
speed_deadline=0.6;

time_everything=GetSecs-1000;
extra_adder=0;
extra_iti_counter=0;
shuffle_counter=0;
extra_trial_counter=0;
skipped_trials=zeros(1,nr_trials);
go_through_while_once=false;
repeat_loop=false;
loop_counter=0;

while go_through_while_once==false ||sum(skipped_trials)~0 %go through once anyway and then only if we skipped trials
    
    repeat_trials=find(skipped_trials~=0);%gives us positions -> actual trial numbers we skipped
    if isempty(repeat_trials)%first time through
       nr_trial=nr_trials; 
    else
        nr_trials=length(repeat_trials);
        repeat_loop=true;
    end
    
    skipped_trials=zeros(1,nr_trials); %reset this each time


    %% Trial Loop
    for trial=1:nr_trials
        loop_counter=loop_counter+1;
        instr=1;
        extra_iti=0;
        signal_jitter=gamrnd(1,150)/1000;
        while signal_jitter > 1;
            signal_jitter=gamrnd(1,150)/1000;
        end

        if repeat_loop==false
            trial=trial;
        else
          trial=repeat_trials(trial);
        end 

        %take appropriate conditions from randomisation 
        lvl_coherence=coherence_order(trial);
        direction=direction_order(trial); %direcions randomly drawn. not part of initial randomisation
        bin=bin_order(trial);

        fixation(window,white,x_centre,y_centre); %fixation cross function

        if tms_bins(bin)>0 %only if it wants to do tms next
            a=(GetSecs-time_everything+1+signal_jitter)+((tms_bins(bin)-bin_interval)/1000)
            if (GetSecs-time_everything+1+signal_jitter)+((tms_bins(bin)-bin_interval)/1000)<5

                % if the inter_stimulus_interval is already over 4 seconds, we
                % add as much as we need
                if (GetSecs-time_everything+1+signal_jitter)+((tms_bins(bin)-bin_interval)/1000)>4
                    b=(GetSecs-time_everything+1+signal_jitter)+((tms_bins(bin)-bin_interval)/1000)
                    extra_iti=5-((GetSecs-time_everything+1+signal_jitter)+((tms_bins(bin)-bin_interval)/1000))
                    cross=15; 
                    x_coords=[-cross, cross, 0, 0];
                    y_coords=[0, 0, -cross, cross];
                    coords=[x_coords; y_coords];
                    Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
                    Screen('Flip', window);
                    WaitSecs(extra_iti);
                    extra_iti_counter=extra_iti_counter+1
                    extra_adder=extra_adder+extra_iti
                    fprintf(File1,'\r\n %f  \r\n',extra_iti)%this is the ITI before the folloowing trial!

                else
                    stop=0;
                    for i=1:length(bin_order)-trial %goes down list, taking into account how far it can go
                        if bin_order(trial+i)>4 && stop==0
                            a_temp=bin_order(trial);
                            b_temp=bin_order(trial+i);
                            c_temp=coherence_order(trial);
                            d_temp=coherence_order(trial+i);
                            e_temp=direction_order(trial);
                            f_temp=direction_order(trial+i);

                            bin_order(trial)=b_temp;
                            bin_order(trial+i)=a_temp;
                            coherence_order(trial)=d_temp;
                            coherence_order(trial+i)=c_temp;
                            direction_order(trial)=f_temp;
                            direction_order(trial+i)=e_temp;

                            bin=bin_order(trial);
                            lvl_coherence=coherence_order(trial);
                            direction=direction_order(trial);
                            stop=1;
                            shuffle_counter=shuffle_counter+1
                        end
                    end
                    if stop==0%if nothing's there to shuffle
                        skipped_trials(trial)=1;
                        lvl_coherence=coherence_order(randi(nr_trials,1,1));  
                        direction=direction_order(randi(nr_trials,1,1));
                        bin=6; %makes tmms_bins(bin) zero
                        instr=0;
                        trial=0;
                        extra_trial_counter=extra_trial_counter+1
                    end
                end
            end
        end
        
        if tms_bins(bin)>0
            stim_time=randi([tms_bins(bin)-bin_interval,tms_bins(bin)]);
        else
            stim_time=[];
        end

        par2.File2=File2;
        par2.signal_jitter=signal_jitter;
        par2.lvl_coherence=lvl_coherence;
        par2.direction=direction;
        par2.coherence=coherence;
        par2.x_centre=x_centre;
        par2.y_centre=y_centre;
        par2.window=window;
        par2.white=white;
        par2.File1=File1;
        par2.vbl=vbl;
        par2.ifi=ifi;
        par2.trial=trial;
        par2.buttons=buttons;
        par2.deg=deg;
        par2.signal_duration=signal_duration;
        par2.instr=instr;
        par2.stim_time=stim_time;
        par2.easy_hard_condition=[];
        par2=struct2cell(par2);


        [rt, accuracy,time_everything]=TrialLoop(par2{:});

        %% Feedback
        if rt<speed_deadline && rt>0
            if accuracy==1;
                feedback='Correct';
                reward=0.008;
            else
                 feedback='Incorrect';
                  reward=0.004;
            end
            feedback_colour=0;
            text_colour=white;
            text_size=30;
        elseif rt > speed_deadline && rt>0
            feedback='TOO SLOW';
            feedback_colour=[1 0 0];
            text_colour=[0 1 0];
            text_size=50;
            reward=0;
        else
            feedback='Too fast.';
            reward=0;
            feedback_colour=0;
            text_colour=white;
            text_size=30; 
        end
        %Text setting
        Screen(window,'FillRect',feedback_colour);
        Screen('TextSize',window, text_size);
        Screen('TextFont',window,'Times');
        points_text=sprintf(' %s \n\n Reward: � %1.4f', feedback, reward);
        DrawFormattedText(window,points_text,'center','center',text_colour);
        Screen('Flip',window);
        WaitSecs(0.7); 
        Screen(window,'FillRect',0);
        Screen('Flip',window);

        %Save speed deadline
        fprintf(File1,' \t %f ',speed_deadline);
        total_reward=total_reward+reward;

        %% add 1s ITI after red screen
        if feedback_colour==[1 0 0]
            cross=15; 
            x_coords=[-cross, cross, 0, 0];
            y_coords=[0, 0, -cross, cross];
            coords=[x_coords; y_coords];
            Screen('DrawLines', window, coords,2, white, [x_centre, y_centre]); % window, xy, linewidth,colour, centre
            Screen('Flip', window);
            WaitSecs(1);
        end  

        %% Speed Staircase
        if lvl_coherence==2
            q_speed=QuestUpdate(q_speed, speed_deadline,accuracy);
            speed_deadline=QuestQuantile(q_speed);
            if speed_deadline>0.75
                speed_deadline=0.75;
            elseif speed_deadline<0.45
                speed_deadline=0.45;
            end
         end      

        %% Break
        if loop_counter/50==round(loop_counter/50) && trial>0
            Screen('TextSize',window, 30);
            Screen('TextFont',window,'Times');
            points_text=sprintf(' Break. \n\n (Press any key to continue)');
            DrawFormattedText(window,points_text,'center','center',white);
            Screen('Flip',window);
            KbStrokeWait;
        end
    end
    go_through_while_once=true
end
speed_order=[bin_order', coherence_order', direction_order'];
save('speed_order');
shuffle_counter
extra_iti_counter
extra_trial_counter

end
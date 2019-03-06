function[] = SARSA(env)
runRewards = [];
for numRuns = 1:1:10
% Algorithm Parameters
alg.alpha = 0.5;
alg.eps = 0.1;
alg.gamma = 1;  % No discounting

alg.numEpisodes = 200;

alg.Q_agent = zeros(env.rowDim, env.colDim, env.numAgentActions());
alg.Q_adversary = zeros(env.rowDim, env.colDim, env.numAdversaryActions());

alg.n = 1;

% Start the episode
totalRewards = [];
for epNum = 1:1:alg.numEpisodes
    epNum
    
    % Initialize and store S0 != terminal
    state = env.startState;
    
    agentStates = [state];
    agentActions = [];
    agentRewards = [0];
    
    advStates = [state];
    advActions = [];
    advRewards = [0];
    
    while 1 
        % Take action At
        agentActionNum = getAgentAction(env, alg, state);
        [agentNextState, agentReward, agentDone] = env.stepAgent(state, agentActionNum);
        
        % Adversary's turn to modify the position
        if agentDone % Do nothing
            advNextState = agentNextState;
            advReward = agentReward;
            advDone = agentDone;
        else
            advActionNum = getAdversaryAction(env, alg, agentNextState);
            [advNextState, advReward, advDone] = env.stepAdversary(agentNextState, advActionNum);
        end
        
        if agentReward == -100
            advReward = 100;
        end
        
        % Observe and store the next reward as Rt+1 and the next state as
        % S_t+1
        agentStates = [agentStates; advNextState];  % Update with state it's moved to
        agentActions = [agentActions; agentActionNum];
        agentRewards = [agentRewards; -advReward];
        
        advStates = [advStates; advNextState];
        advActions = [advActions; advActionNum];
        advRewards = [advRewards; advReward];
        
        % Agent is now in the advNextState location
        agentActionNumNext = getAgentAction(env,alg,advNextState);
        agentActionValNext = alg.Q_agent(advNextState(1), advNextState(2), agentActionNumNext);
        
        % Wind's next action depends on the agent's next state
        moveAgentState = env.stepAgent(advNextState, agentActionNumNext);
        advActionNumNext = getAdversaryAction(env,alg,moveAgentState);
        advActionValNext = alg.Q_adversary(moveAgentState(1), moveAgentState(2), advActionNumNext);
        
        
        alg.Q_agent(state(1), state(2), agentActionNum) = ...
            alg.Q_agent(state(1), state(2), agentActionNum) + ...
            alg.alpha * ...
            (-advReward + alg.gamma * agentActionValNext - ...
            alg.Q_agent(state(1), state(2), agentActionNum));
        
        alg.Q_adversary(state(1), state(2), advActionNum) = ...
            alg.Q_adversary(state(1), state(2), advActionNum) + ...
            alg.alpha * ...
            (advReward + alg.gamma * advActionValNext - ...
            alg.Q_adversary(state(1), state(2), advActionNum));
        
        state = advNextState;
        
        % Make sure terminal state stays at 0
        alg.Q_agent(env.endState(1), env.endState(2), :) = 0;
        alg.Q_adv(env.endState(1), env.endState(2), :) = 0;
        
        if agentDone || advDone
           break 
        end
    end
    
    totalRewards = [totalRewards; sum(agentRewards)];
    
end

    runRewards = [runRewards totalRewards];
end
plot(mean(runRewards,2))
ylim([-100,0])
save("Results.mat")

end

function[chosenAction] = getAgentAction(env, alg, state)
% Take the greedy action with probability 1-epsilon
greedy = binornd(1, 1-alg.eps);

actions = env.validActionsAgent(state);

% Choose A from S using policy derived from Q (eps-greedy)
currQ = alg.Q_agent(state(1), state(2), actions);

% Take the greedy action with probability 1-epsilon
greedy = binornd(1, 1-alg.eps);

if greedy
    maxQ = max(currQ); % Find the maximum value
    maxIdx = find(currQ == maxQ);
    validActionNum = maxIdx(randi([1,length(maxIdx)]));
else
    validActionNum = randi([1,length(actions)]);
end

chosenAction = actions(validActionNum);
end

function[chosenAction] = getAdversaryAction(env, alg, state)
% Take the greedy action with probability 1-epsilon
greedy = binornd(1, 1-alg.eps);

actions = env.validActionsAdversary(state);

% Choose A from S using policy derived from Q (eps-greedy)
currQ = alg.Q_adversary(state(1), state(2), actions);

% Take the greedy action with probability 1-epsilon
greedy = binornd(1, 1-alg.eps);

if greedy
    maxQ = max(currQ); % Find the maximum value
    maxIdx = find(currQ == maxQ);
    validActionNum = maxIdx(randi([1,length(maxIdx)]));
else
    validActionNum = randi([1,length(actions)]);
end

chosenAction = actions(validActionNum);
end
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl
mpl.rcParams['axes.labelsize'] = 20
mpl.rcParams['axes.titlesize'] = 20
mpl.rcParams['xtick.direction'] = 'in'
mpl.rcParams['xtick.major.size'] = 10
mpl.rcParams['xtick.major.width'] = 2.5
mpl.rcParams['xtick.minor.size'] = 8
mpl.rcParams['xtick.minor.width'] = 1.2
mpl.rcParams['xtick.labelsize'] = 15
mpl.rcParams['xtick.top'] = True
mpl.rcParams['ytick.direction'] = 'in'
mpl.rcParams['ytick.major.size'] = 14
mpl.rcParams['ytick.major.width'] = 2.5
mpl.rcParams['ytick.minor.size'] = 8
mpl.rcParams['ytick.minor.width'] = 1.2
mpl.rcParams['ytick.labelsize'] = 15
mpl.rcParams['ytick.right'] = True
mpl.rcParams['legend.fontsize'] = 15
mpl.rcParams['axes.linewidth'] = 2.5
mpl.rcParams['lines.linewidth'] = 3
mpl.rcParams['lines.markersize'] = 10

data = pd.read_csv('test_NPQ.RPT', sep='\s+')

colors = ['C0', 'C2', 'C1', 'darkred']
markers = ['x', 'D', 'x', 'o']
mfcolors = [c for c in colors]
labels = [r'$\lambda_1=470\,$nm', r'$\lambda_2=520\,$nm', r'$\lambda_3=645\,$nm', r'$\lambda_4=665\,$nm']
mfcolors[3] = 'None'

def sec_(s):
    l = s.split(':')
    return int(l[0]) * 3600 + int(l[1]) * 60 + int(l[2])
sec = np.vectorize(sec_)

figs_NPQ = {}
for i, k in enumerate(['AllOpePSII', 'opePSII', 'maxPSII', 'NPQEstim']):
    figs_NPQ[i], ax = plt.subplots()
    for ch, (c, m, mfc, lbl) in enumerate(zip(colors, markers, mfcolors, labels), start=1):
        ch = str(ch)
        time = sec(data['Time'])
        time0 = time[0]
        if k == 'AllOpePSII': Y = (data['Fm'+ch]-data['F'+ch])/data['Fm'+ch]

        data_AL = data[data['PAR']>16]
        if k != 'AllOpePSII': time = sec(data_AL['Time'])
        fm = np.asarray(data_AL['Fm'+ch])
        f = np.asarray(data_AL['F'+ch])
        fq = fm - f
        if k == 'opePSII': Y = fq/fm  
            
        data_0 = data.iloc[data_AL.index+1]
        f0_star = np.asarray(data_0['F'+ch])
        f0m_star = np.asarray(data_0['Fm'+ch])
        f0 = 1/(1/f0_star-1/f0m_star+1/fm)
        fv = fm-f0 
        if k == 'maxPSII': Y = fv/fm

        data_DA = data.iloc[:data_AL.index[0]]
        fm_DA = data_DA['Fm'+ch].iloc[-1]
        if k == 'NPQEstim': Y = (fm_DA-fm)/fm
        
        Y[Y<0] = np.nan
        plt.plot((time - time0)/60, Y, lw=0, marker=m, color=c, markerfacecolor=mfc, label = lbl)
        # plt.plot((time - time[0])/60, Y*data['PAR']*0.84*0.5, lw=0, marker=m, color=c, markerfacecolor=mfc)
        
    # ax.set_ylim([0, None])
    # ax.set_xlim([-10, 130])
    ax.set_xlabel('Time  /  min')
    if k == 'AllOpePSII': ax.set_ylabel('Yield')
    if k == 'opePSII': ax.set_ylabel('PSII operating efficiency\n'
                                     +r"$K_\mathrm{P}'[Q_A]'/(K_\mathrm{F}+K_\mathrm{NPQ}'+K_\mathrm{P}'[Q_A]')$")
    if k == 'maxPSII': ax.set_ylabel('PSII maximal efficiency\n'
                                     +r"$K_\mathrm{P}'/(K_\mathrm{F}+K_\mathrm{NPQ}'+K_\mathrm{P}')$")     
    if k == 'NPQEstim': ax.set_ylabel('NPQ: ' + r"$(K_\mathrm{NPQ}'-K_\mathrm{NPQ})/K_\mathrm{NPQ}$")
    plt.legend()

    ax.spines["right"].set_visible(False)
    ax_AL = ax.twinx()
    time = sec(data['Time'])
    time = np.repeat(time, 2)
    time = [time[0]-20]+list(time)
    PAR = list(np.repeat(data['PAR'], 2))
    ax_AL.plot((time[:-1] - time[0])/60, PAR, alpha=0.35, color = 'grey')
    ax_AL.set_ylabel('PAR  /  µE')
    ax_AL.yaxis.label.set_color('grey')
    ax_AL.spines["right"].set_edgecolor('grey')
    ax_AL.tick_params(axis='y', colors='grey')